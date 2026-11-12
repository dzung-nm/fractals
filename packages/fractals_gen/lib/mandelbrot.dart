import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'color_palette.dart';

const bool kIsWeb = identical(0, 0.0);

class MandelbrotParams {
  // width and height of the image in pixels
  final int width;
  final int height;

  // center of the image in the complex plane
  final double centerX;
  final double centerY;

  // span of the image in the complex plane
  final double spanX;
  final double spanY;

  // maximum number of iterations for the Mandelbrot algorithm
  final int maxIter;

  // index of the color palette to use for rendering
  final int paletteIndex;

  MandelbrotParams({
    required this.width,
    required this.height,
    required this.centerX,
    required this.centerY,
    required this.spanX,
    required this.spanY,
    required this.maxIter,
    required this.paletteIndex,
  });
}

class GeneratePixelsTask {
  final MandelbrotParams params;

  // start and end y-coordinates for the portion of the image to generate
  // (used for parallel processing)
  final int startY;
  final int endY;

  GeneratePixelsTask({
    required this.params,
    required this.startY,
    required this.endY,
  });
}

Uint8List generatePixelsIsolate(GeneratePixelsTask task) {
  final palette = paletteStops[task.params.paletteIndex];
  final width = task.params.width;
  final height = task.params.height;
  final centerX = task.params.centerX;
  final centerY = task.params.centerY;
  final spanX = task.params.spanX;
  final spanY = task.params.spanY;
  final maxIter = task.params.maxIter;

  final startY = task.startY;
  final endY = task.endY;

  // Calculate the minimum x and y coordinates in the complex plane
  final xMin = centerX - spanX / 2;
  final yMin = centerY - spanY / 2;

  // Calculate the step size for each pixel in the complex plane
  final xStep = spanX / width;
  final yStep = spanY / height;

  // Allocate a buffer to store the RGBA pixel data for the Mandelbrot image.
  final pixels = Uint8List(width * (endY - startY) * 4);

  for (var y = startY; y < endY; y++) {
    final cy = yMin + y * yStep;
    final cySquared = cy * cy;
    var offset = (y - startY) * width * 4;

    for (var x = 0; x < width; x++) {
      // Map the pixel coordinates to the complex plane.
      final cx = xMin + x * xStep;

      // Skip iteration for points in the main cardioid
      final cardioidX = cx - 0.25;
      final q = cardioidX * cardioidX + cySquared;
      final inMainCardioid = q * (q + cardioidX) <= 0.25 * cySquared;

      // Skip iteration for points in the period-2 bulb as well.
      final bulbX = cx + 1.0;
      final inPeriod2Bulb = bulbX * bulbX + cySquared <= 0.0625;

      final inKnownInterior = inMainCardioid || inPeriod2Bulb;

      var zx = 0.0;
      var zy = 0.0;
      var magnitudeSquared = 0.0;
      var iter = 0;

      while (!inKnownInterior && magnitudeSquared <= 4.0 && iter < maxIter) {
        final temp = zx * zx - zy * zy + cx;
        zy = 2.0 * zx * zy + cy;
        zx = temp;
        magnitudeSquared = zx * zx + zy * zy;
        iter++;
      }

      if (inKnownInterior || iter == maxIter) {
        // Points inside the Mandelbrot set remain black.
        pixels[offset++] = 0;
        pixels[offset++] = 0;
        pixels[offset++] = 0;
      } else {
        // Smooth the escape count to reduce harsh bands between iterations.
        // Compute the smooth iteration count for coloring.
        final smoothIter =
            iter + 1 - math.log(0.5 * math.log(magnitudeSquared)) / math.ln2;

        // Map the smooth iteration count to a position within the color palette.
        // Normalize the smooth iteration count to a value between 0 and 1,
        // then scale it to the palette length.
        final palettePosition =
            ((smoothIter / 24.0) % 1.0) * (palette.length - 1);

        // Determine the lower and upper color stops for interpolation.
        final lowerStop = palettePosition.floor();

        // Compute the fractional part of the palette position for blending.
        final blend = palettePosition - lowerStop;

        // Retrieve the start and end colors for interpolation.
        final start = palette[lowerStop];
        final end = palette[lowerStop + 1];

        pixels[offset++] = (start[0] + (end[0] - start[0]) * blend).round();
        pixels[offset++] = (start[1] + (end[1] - start[1]) * blend).round();
        pixels[offset++] = (start[2] + (end[2] - start[2]) * blend).round();
      }

      // Set the alpha channel to fully opaque.
      pixels[offset++] = 255;
    }
  }

  return pixels;
}

class MandelbrotImage {
  final Uint8List pixels;
  final Duration computeTime;

  MandelbrotImage({required this.pixels, required this.computeTime});
}

Future<MandelbrotImage> generateImage(MandelbrotParams params) async {
  final stopwatch = Stopwatch()..start();

  // Calculate the number of isolates to spawn based on
  // kIsWeb OR the number of available processors.
  final numIsolates = kIsWeb ? 1 : Platform.numberOfProcessors;

  // Calculate the height of each portion of the image to be generated by each isolate.
  final portionHeight = (params.height / numIsolates).ceil();

  List<Future<Uint8List>> pixelsFutures = [];

  // Spawn isolates to generate portions of the Mandelbrot image in parallel.
  for (var i = 0; i < numIsolates; i++) {
    final startY = i * portionHeight;
    final endY = math.min(startY + portionHeight, params.height);

    if (startY >= endY) {
      // If the startY is greater than or equal to endY, skip this isolate.
      continue;
    }

    final task = GeneratePixelsTask(
      params: params,
      startY: startY,
      endY: endY,
    );

    pixelsFutures.add(Isolate.run(() => generatePixelsIsolate(task)));
  }

  // Wait for all isolates to complete and collect their pixel data.
  final pixelsList = await Future.wait(pixelsFutures);

  // Combine all pixel data into a single Uint8List.
  final combinedPixels = Uint8List(params.width * params.height * 4);
  var offset = 0;
  for (final pixels in pixelsList) {
    combinedPixels.setRange(offset, offset + pixels.length, pixels);
    offset += pixels.length;
  }

  stopwatch.stop();
  
  return MandelbrotImage(
    pixels: combinedPixels,
    computeTime: stopwatch.elapsed,
  );
}
