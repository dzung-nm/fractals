import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'color_palette.dart';

const _juliaCReal = -0.5125;
const _juliaCImaginary = 0.5213;

Uint8List generateJuliaPixels(List<Object> args) {
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
  final pixels = Uint8List(width * (endY - startY) * 4);

  for (var y = startY; y < endY; y++) {
    final initialY = yMin + y * yStep;
    var offset = (y - startY) * width * 4;

    for (var x = 0; x < width; x++) {
      var zx = xMin + x * xStep;
      var zy = initialY;
      var magnitudeSquared = 0.0;
      var iter = 0;

      while (magnitudeSquared <= 4.0 && iter < maxIter) {
        final temp = zx * zx - zy * zy + _juliaCReal;
        zy = 2.0 * zx * zy + _juliaCImaginary;
        zx = temp;
        magnitudeSquared = zx * zx + zy * zy;
        iter++;
      }

      if (iter == maxIter) {
        pixels[offset++] = 0;
        pixels[offset++] = 0;
        pixels[offset++] = 0;
      } else {
        final smoothIter =
            iter + 1 - math.log(0.5 * math.log(magnitudeSquared)) / math.ln2;
        final palettePosition =
            ((smoothIter / 24.0) % 1.0) * (palette.length - 1);
        final lowerStop = palettePosition.floor();
        final blend = palettePosition - lowerStop;
        final start = palette[lowerStop];
        final end = palette[lowerStop + 1];

        pixels[offset++] = (start[0] + (end[0] - start[0]) * blend).round();
        pixels[offset++] = (start[1] + (end[1] - start[1]) * blend).round();
        pixels[offset++] = (start[2] + (end[2] - start[2]) * blend).round();
      }

      pixels[offset++] = 255;
    }
  }

  return pixels;
}

void juliaWorker(List<Object> message) {
  final sendPort = message[0] as SendPort;
  final args = message[1] as List<Object>;
  sendPort.send(generateJuliaPixels(args));
}

Future<Uint8List> runJuliaWorker(List<Object> args) async {
  final responsePort = ReceivePort();
  final errorPort = ReceivePort();
  Isolate? isolate;

  try {
    isolate = await Isolate.spawn(juliaWorker, <Object>[
      responsePort.sendPort,
      args,
    ], onError: errorPort.sendPort);

    final response = await Future.any<dynamic>([
      responsePort.first,
      errorPort.first.then<void>((error) {
        throw StateError('Julia worker failed: $error');
      }),
    ]);

    if (response is! Uint8List) {
      throw StateError('Julia worker returned an invalid pixel buffer.');
    }
    return response;
  } finally {
    responsePort.close();
    errorPort.close();
    isolate?.kill(priority: Isolate.immediate);
  }
}
