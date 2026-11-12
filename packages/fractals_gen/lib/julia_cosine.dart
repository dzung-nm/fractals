import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

const bool kIsWeb = identical(0, 0.0);

class JuliaCosineParams {
  // width and height of the image in pixels
  final int width;
  final int height;

  // center of the image in the complex plane
  final double centerX;
  final double centerY;

  // span of the image in the complex plane
  final double spanX;
  final double spanY;

  // maximum number of iterations
  final int maxIter;

  // parameters for the Julia set
  final double juliaCRe;
  final double juliaCIm;

  JuliaCosineParams({
    required this.width,
    required this.height,
    required this.centerX,
    required this.centerY,
    required this.spanX,
    required this.spanY,
    required this.maxIter,
    required this.juliaCRe,
    required this.juliaCIm,
  });
}

// Calculate a color based on a cosine palette.
// This function generates a smooth gradient of colors using cosine functions,
// which can be used to create visually appealing color palettes for fractals
// or other visualizations.
List<int> getCosineColor(double t) {
  // Constants for the cosine color palette
  // aR, aG, aB: Base color values (0.5 for each channel)
  // bR, bG, bB: Amplitude of the cosine wave for each color channel (0.5 for each channel)
  // cR, cG, cB: Frequency of the cosine wave for each color channel (1.0 for each channel)
  // dR, dG, dB: Phase shift for the cosine wave for each color channel (0.0 for red, 0.10 for green, 0.20 for blue)
  const aR = 0.5, aG = 0.5, aB = 0.5;
  const bR = 0.5, bG = 0.5, bB = 0.5;
  const cR = 1.0, cG = 1.0, cB = 1.0;
  const dR = 0.0, dG = 0.10, dB = 0.20;

  final double twoPi = 2.0 * math.pi;

  final r = (255.0 * (aR + bR * math.cos(twoPi * (cR * t + dR)))).round().clamp(
    0,
    255,
  );
  final g = (255.0 * (aG + bG * math.cos(twoPi * (cG * t + dG)))).round().clamp(
    0,
    255,
  );
  final b = (255.0 * (aB + bB * math.cos(twoPi * (cB * t + dB)))).round().clamp(
    0,
    255,
  );

  return [r, g, b];
}

Uint8List generatePixelsIsolate(GeneratePixelsTask task) {
  final width = task.params.width;
  final height = task.params.height;
  final centerX = task.params.centerX;
  final centerY = task.params.centerY;
  final spanX = task.params.spanX;
  final spanY = task.params.spanY;
  final maxIter = task.params.maxIter;
  final juliaCRe = task.params.juliaCRe;
  final juliaCIm = task.params.juliaCIm;

  final startY = task.startY;
  final endY = task.endY;

  final xMin = centerX - spanX / 2;
  final yMin = centerY - spanY / 2;

  final xStep = spanX / width;
  final yStep = spanY / height;

  final pixels = Uint8List(width * (endY - startY) * 4);

  // Establish anti-aliasing level (2 = 2x2 grid = 4 samples per pixel)
  const int aaLevel = 2;
  const int totalSamples = aaLevel * aaLevel;

  for (var y = startY; y < endY; y++) {
    var offset = (y - startY) * width * 4;

    for (var x = 0; x < width; x++) {
      int rSum = 0, gSum = 0, bSum = 0;

      // Super-sampling: Divide one pixel into a grid (aaLevel x aaLevel)
      for (int sy = 0; sy < aaLevel; sy++) {
        for (int sx = 0; sx < aaLevel; sx++) {
          // Get the sub-pixel coordinates
          var zx = xMin + (x + sx / aaLevel) * xStep;
          var zy = yMin + (y + sy / aaLevel) * yStep;

          var magnitudeSquared = 0.0;
          var iter = 0;

          while (magnitudeSquared <= 256.0 && iter < maxIter) {
            final temp = zx * zx - zy * zy + juliaCRe;
            zy = 2.0 * zx * zy + juliaCIm;
            zx = temp;
            magnitudeSquared = zx * zx + zy * zy;
            iter++;
          }

          if (iter == maxIter) {
            // For points that do not escape (inside the Julia set), we assign black color.
            rSum += 0;
            gSum += 0;
            bSum += 0;
          } else {
            // For points that escape, we calculate a smooth iteration count to get a gradient color.
            final smoothIter =
                iter +
                1 -
                math.log(0.5 * math.log(magnitudeSquared)) / math.ln2;

            // Color speed parameter. You can change the number 40.0 to adjust the thickness of the gradient band.
            final t = smoothIter / 40.0;

            final color = getCosineColor(t);
            rSum += color[0];
            gSum += color[1];
            bSum += color[2];
          }
        }
      }

      // Average the colors of the sub-pixels to create the final pixel color
      pixels[offset++] = rSum ~/ totalSamples;
      pixels[offset++] = gSum ~/ totalSamples;
      pixels[offset++] = bSum ~/ totalSamples;
      pixels[offset++] = 255; // Alpha channel
    }
  }

  return pixels;
}

class GeneratePixelsTask {
  final JuliaCosineParams params;

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

class JuliaImage {
  final Uint8List pixels;
  final Duration computeTime;

  JuliaImage({required this.pixels, required this.computeTime});
}

Future<JuliaImage> generateImage(JuliaCosineParams params) async {
  final stopwatch = Stopwatch()..start();

  // Calculate the number of isolates to spawn based on
  // kIsWeb OR the number of available processors.
  final numIsolates = kIsWeb ? 1 : Platform.numberOfProcessors;

  // Calculate the height of each portion of the image to be generated by each isolate.
  final portionHeight = (params.height / numIsolates).ceil();

  List<Future<Uint8List>> pixelsFutures = [];

  // Spawn isolates to generate portions of the Julia image in parallel.
  for (var i = 0; i < numIsolates; i++) {
    final startY = i * portionHeight;
    final endY = math.min(startY + portionHeight, params.height);

    if (startY >= endY) {
      // If the startY is greater than or equal to endY, skip this isolate.
      continue;
    }

    final task = GeneratePixelsTask(params: params, startY: startY, endY: endY);

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

  return JuliaImage(pixels: combinedPixels, computeTime: stopwatch.elapsed);
}
