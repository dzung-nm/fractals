import 'package:flutter/material.dart';
import 'package:fractals_gen/fractals_gen.dart';

import 'fractal_widget.dart';

class HamburgerMenu extends StatelessWidget {
  final FractalType selectedFractal;
  final ColorPalette selectedPalette;
  final ValueChanged<FractalType> onFractalChanged;
  final ValueChanged<ColorPalette> onPaletteChanged;
  final VoidCallback onReset;
  final VoidCallback onSaveImage;

  const HamburgerMenu({
    super.key,
    required this.selectedFractal,
    required this.selectedPalette,
    required this.onFractalChanged,
    required this.onPaletteChanged,
    required this.onReset,
    required this.onSaveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Fractals',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              title: const Text('Fractal type'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<FractalType>(
                  value: selectedFractal,
                  items: FractalType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) onFractalChanged(type);
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('Color palette'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<ColorPalette>(
                  value: selectedPalette,
                  items: ColorPalette.values
                      .map(
                        (palette) => DropdownMenuItem(
                          value: palette,
                          child: Text(palette.label),
                        ),
                      )
                      .toList(),
                  onChanged: (palette) {
                    if (palette != null) onPaletteChanged(palette);
                  },
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset'),
              onTap: onReset,  
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save image as PNG'),
              onTap: onSaveImage,
            ),
          ],
        ),
      ),
    );
  }
}
