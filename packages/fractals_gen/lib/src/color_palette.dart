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