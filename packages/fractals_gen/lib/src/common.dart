import 'dart:typed_data';

class FractalImage {
  final Uint8List pixels;
  final Duration computeTime;

  FractalImage({required this.pixels, required this.computeTime});
}
