import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:fractals_gen/color_palette.dart';
import 'package:fractals_gen/mandelbrot.dart';

void main(List<String> arguments) async {
  final params = MandelbrotParams(
    width: 800,
    height: 600,
    centerX: -0.5,
    centerY: 0.0,
    spanX: 3.0,
    spanY: 2.25,
    maxIter: 1000,
    paletteIndex: ColorPalette.inferno.index,
  );

  final mandelbrotImage = await generateImage(params);
  print('Mandelbrot image generated in ${mandelbrotImage.computeTime.inMilliseconds} ms');

  // save the image to a file
  final image = img.Image.fromBytes(
    width: params.width, 
    height: params.height, 
    bytes: mandelbrotImage.pixels.buffer,
    numChannels: 4,
    format: img.Format.uint8
  );
  final png = img.encodePng(image);
  await File('data/mandelbrot.png').writeAsBytes(png);
}
