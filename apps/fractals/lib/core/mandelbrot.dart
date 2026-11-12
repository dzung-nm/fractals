import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'color_palette.dart';

Uint8List generateMandelbrotPixels(List<Object> args) {
  final width = args[0] as int;
  final height = args[1] as int;
  final centerX = args[2] as double;
  final centerY = args[3] as double;
  final spanX = args[4] as double;
  final spanY = args[5] as double;
  final maxIter = args[6] as int;
  final paletteIndex = args[7] as int;
  final startY = args[8] as int;
  final endY = args[9] as int;
  final palette = paletteStops[paletteIndex];

  final xMin = centerX - spanX / 2;
  final yMin = centerY - spanY / 2;
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

void mandelbrotWorker(List<Object> message) {
  final sendPort = message[0] as SendPort;
  final args = message[1] as List<Object>;
  sendPort.send(generateMandelbrotPixels(args));
}

Future<Uint8List> runMandelbrotWorker(List<Object> args) async {
  final responsePort = ReceivePort();
  final errorPort = ReceivePort();
  Isolate? isolate;

  try {
    isolate = await Isolate.spawn(mandelbrotWorker, <Object>[
      responsePort.sendPort,
      args,
    ], onError: errorPort.sendPort);

    final response = await Future.any<dynamic>([
      responsePort.first,
      errorPort.first.then<void>((error) {
        throw StateError('Mandelbrot worker failed: $error');
      }),
    ]);

    if (response is! Uint8List) {
      throw StateError('Mandelbrot worker returned an invalid pixel buffer.');
    }
    return response;
  } finally {
    responsePort.close();
    errorPort.close();
    isolate?.kill(priority: Isolate.immediate);
  }
}
