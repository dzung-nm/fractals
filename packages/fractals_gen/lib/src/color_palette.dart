import 'dart:math' as math;
import 'dart:typed_data';

enum ColorPalette {
  inferno('Inferno'),
  ocean('Ocean'),
  aurora('Aurora');

  const ColorPalette(this.label);

  final String label;
}

const paletteStops = <List<List<int>>>[
  // Inferno: violet, red, orange and gold.
  [
    [8, 5, 30],
    [75, 20, 120],
    [190, 35, 75],
    [250, 105, 25],
    [255, 225, 90],
    [8, 5, 30],
  ],
  // Ocean: midnight blue, blue, cyan and seafoam.
  [
    [3, 8, 38],
    [20, 55, 145],
    [25, 155, 210],
    [90, 235, 220],
    [225, 255, 240],
    [3, 8, 38],
  ],
  // Aurora: teal, green, violet and pink.
  [
    [5, 12, 40],
    [0, 115, 120],
    [80, 220, 155],
    [110, 90, 210],
    [245, 115, 190],
    [5, 12, 40],
  ],
];

/// A dense, linear-light color lookup table for the small authoring palettes
/// above.  Interpolating in linear light keeps gradients from becoming muddy
/// in their darker ranges and the table avoids doing color math per pixel.
class PaletteLut {
  static const int size = 1024;

  final Uint8List _rgb;

  PaletteLut._(this._rgb);

  factory PaletteLut.fromStops(List<List<int>> stops) {
    final rgb = Uint8List(size * 3);
    final segmentCount = stops.length - 1;

    for (var i = 0; i < size; i++) {
      final position = i / (size - 1) * segmentCount;
      final lower = position.floor().clamp(0, segmentCount - 1).toInt();
      final blend = position - lower;
      final start = stops[lower];
      final end = stops[lower + 1];
      final offset = i * 3;

      for (var channel = 0; channel < 3; channel++) {
        final startLinear = math.pow(start[channel] / 255.0, 2.2).toDouble();
        final endLinear = math.pow(end[channel] / 255.0, 2.2).toDouble();
        final linear = startLinear + (endLinear - startLinear) * blend;
        rgb[offset + channel] = (math.pow(linear, 1 / 2.2) * 255.0)
            .round()
            .clamp(0, 255)
            .toInt();
      }
    }

    return PaletteLut._(rgb);
  }

  void writeColor(double normalizedPosition, Uint8List pixels, int offset) {
    final index = _offset(normalizedPosition);
    pixels[offset] = _rgb[index];
    pixels[offset + 1] = _rgb[index + 1];
    pixels[offset + 2] = _rgb[index + 2];
  }

  int channelAt(double normalizedPosition, int channel) =>
      _rgb[_offset(normalizedPosition) + channel];

  int _offset(double normalizedPosition) {
    final wrapped = normalizedPosition - normalizedPosition.floor();
    return (wrapped * (size - 1)).round() * 3;
  }
}
