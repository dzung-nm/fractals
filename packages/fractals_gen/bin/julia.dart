import 'dart:io';
import 'package:image/image.dart' as img;

import 'package:fractals_gen/color_palette.dart';
import 'package:fractals_gen/julia.dart';

void main(List<String> arguments) async {
  final params = JuliaParams(
    width: 800,
    height: 544,
    centerX: 0.0,
    centerY: 0.0,
    spanX: 3.6765,
    spanY: 2.5,
    maxIter: 200,
    juliaCRe: -0.5125,
    juliaCIm: 0.5213,
    paletteIndex: ColorPalette.inferno.index,
  );

  final juliaImage = await generateImage(params);
  print('Julia image generated in ${juliaImage.computeTime.inMilliseconds} ms');

  // save the image to a file
  final image = img.Image.fromBytes(
    width: params.width, 
    height: params.height, 
    bytes: juliaImage.pixels.buffer,
    numChannels: 4,
    format: img.Format.uint8
  );
  final png = img.encodePng(image);
  await File('data/julia.png').writeAsBytes(png);
}
