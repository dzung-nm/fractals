import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fractals_gen/fractals_gen.dart';

import 'fractal_widget.dart';

class HamburgerMenu extends StatefulWidget {
  final FractalType selectedFractal;
  final ColorPalette selectedPalette;
  final int maxIterations;
  final double juliaCRe;
  final double juliaCIm;
  final bool showPerformanceHud;
  final ValueChanged<FractalType> onFractalChanged;
  final ValueChanged<ColorPalette> onPaletteChanged;
  final ValueChanged<int> onMaxIterationsChanged;
  final void Function(double real, double imaginary) onJuliaChanged;
  final ValueChanged<bool> onPerformanceHudChanged;
  final VoidCallback onReset;
  final VoidCallback onSaveImage;

  const HamburgerMenu({
    super.key,
    required this.selectedFractal,
    required this.selectedPalette,
    required this.maxIterations,
    required this.juliaCRe,
    required this.juliaCIm,
    required this.showPerformanceHud,
    required this.onFractalChanged,
    required this.onPaletteChanged,
    required this.onMaxIterationsChanged,
    required this.onJuliaChanged,
    required this.onPerformanceHudChanged,
    required this.onReset,
    required this.onSaveImage,
  });

  @override
  State<HamburgerMenu> createState() => _HamburgerMenuState();
}

class _HamburgerMenuState extends State<HamburgerMenu> {
  late final TextEditingController _juliaCReController;
  late final TextEditingController _juliaCImController;

  @override
  void initState() {
    super.initState();
    _juliaCReController = TextEditingController(
      text: widget.juliaCRe.toString(),
    );
    _juliaCImController = TextEditingController(
      text: widget.juliaCIm.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant HamburgerMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.juliaCRe != widget.juliaCRe) {
      _juliaCReController.text = widget.juliaCRe.toString();
    }
    if (oldWidget.juliaCIm != widget.juliaCIm) {
      _juliaCImController.text = widget.juliaCIm.toString();
    }
  }

  @override
  void dispose() {
    _juliaCReController.dispose();
    _juliaCImController.dispose();
    super.dispose();
  }

  void _updateJulia() {
    final real = double.tryParse(_juliaCReController.text.trim());
    final imaginary = double.tryParse(_juliaCImController.text.trim());
    if (real == null || imaginary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid real and imaginary values.')),
      );
      return;
    }
    widget.onJuliaChanged(real, imaginary);
  }

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
                  value: widget.selectedFractal,
                  items: FractalType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (type) {
                    if (type != null) widget.onFractalChanged(type);
                  },
                ),
              ),
            ),
            if (widget.selectedFractal == FractalType.julia) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _juliaCReController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Julia real (juliaCre)',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _juliaCImController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Julia imaginary (juliaCIm)',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _updateJulia,
                    child: const Text('update'),
                  ),
                ),
              ),
            ],
            ListTile(
              title: const Text('Color palette'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<ColorPalette>(
                  value: widget.selectedPalette,
                  items: ColorPalette.values
                      .map(
                        (palette) => DropdownMenuItem(
                          value: palette,
                          child: Text(palette.label),
                        ),
                      )
                      .toList(),
                  onChanged: (palette) {
                    if (palette != null) widget.onPaletteChanged(palette);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Iterations: ${widget.maxIterations}'),
                  Slider(
                    min: 100,
                    max: 500,
                    divisions: 400,
                    value: widget.maxIterations.toDouble(),
                    label: '${widget.maxIterations}',
                    onChanged: (value) =>
                        widget.onMaxIterationsChanged(value.round()),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Reset'),
              onTap: widget.onReset,
            ),
            ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Save image as PNG'),
              onTap: widget.onSaveImage,
            ),
            CheckboxListTile(
              title: const Text('Show performance HUD'),
              value: widget.showPerformanceHud,
              onChanged: (show) {
                if (show != null) widget.onPerformanceHudChanged(show);
              },
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Exit'),
              onTap: SystemNavigator.pop,
            ),
          ],
        ),
      ),
    );
  }
}
