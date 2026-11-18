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

class _HamburgerMenuState extends State<HamburgerMenu>
    with TickerProviderStateMixin {
  static const _iterationSteps = <int>[100, 200, 300, 400, 500, 600, 700];
  static const _juliaStep = 0.005;

  late final TextEditingController _juliaCReController;
  late final TextEditingController _juliaCImController;

  @override
  void initState() {
    super.initState();
    _juliaCReController = TextEditingController(
      text: _formatJulia(widget.juliaCRe),
    );
    _juliaCImController = TextEditingController(
      text: _formatJulia(widget.juliaCIm),
    );
  }

  @override
  void didUpdateWidget(covariant HamburgerMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.juliaCRe != widget.juliaCRe) {
      _juliaCReController.text = _formatJulia(widget.juliaCRe);
    }
    if (oldWidget.juliaCIm != widget.juliaCIm) {
      _juliaCImController.text = _formatJulia(widget.juliaCIm);
    }
  }

  @override
  void dispose() {
    _juliaCReController.dispose();
    _juliaCImController.dispose();
    super.dispose();
  }

  String _formatJulia(double value) => value.toStringAsFixed(4);

  int get _iterationIndex =>
      List<int>.generate(_iterationSteps.length, (index) => index).reduce(
        (best, index) =>
            (widget.maxIterations - _iterationSteps[index]).abs() <
                (widget.maxIterations - _iterationSteps[best]).abs()
            ? index
            : best,
      );

  void _adjustJulia(TextEditingController controller, double delta) {
    final next = (double.tryParse(controller.text.trim()) ?? 0) + delta;
    final text = _formatJulia(next);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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

  List<Color> _paletteColors(ColorPalette palette) {
    switch (palette.name.toLowerCase()) {
      case 'inferno':
        return const [
          Color(0xFF08051E),
          Color(0xFF4B1478),
          Color(0xFFBE234B),
          Color(0xFFFA6919),
          Color(0xFFFFE15A),
        ];
      case 'ocean':
        return const [
          Color(0xFF030826),
          Color(0xFF143791),
          Color(0xFF199BD2),
          Color(0xFF5AEBDA),
          Color(0xFFE1FFF0),
        ];
      case 'aurora':
        return const [
          Color(0xFF160A37),
          Color(0xFF007378),
          Color(0xFF50DC9B),
          Color(0xFF6E5AD2),
          Color(0xFFF573BE),
        ];
      default:
        return const [Color(0xFF362D66), Color(0xFF9C88FF)];
    }
  }

  LinearGradient _paletteGradient(ColorPalette palette) => LinearGradient(
    colors: _paletteColors(palette),
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C88FF),
      brightness: Brightness.dark,
    );
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF16161E),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF16161E)),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: .42),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  children: [
                    _label('FRACTAL TYPE', scheme),
                    const SizedBox(height: 8),
                    _fractalTypes(scheme),
                    _juliaEditor(scheme),
                    const SizedBox(height: 24),
                    _iterations(scheme),
                    const SizedBox(height: 24),
                    _label('COLOR PALETTE', scheme),
                    const SizedBox(height: 8),
                    _palettes(),
                    const SizedBox(height: 24),
                    _label('DISPLAY', scheme),
                    _performanceHud(),
                    const SizedBox(height: 24),
                    _label('ACTIONS', scheme),
                    const SizedBox(height: 8),
                    _actions(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _exitButton(scheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, ColorScheme scheme) => Text(
    text,
    style: Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 1.2,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    ),
  );

  Widget _fractalTypes(ColorScheme scheme) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: FractalType.values
          .map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type.label),
                selected: type == widget.selectedFractal,
                onSelected: (_) => widget.onFractalChanged(type),
                side: BorderSide(
                  color: type == widget.selectedFractal
                      ? scheme.primary
                      : scheme.outlineVariant,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  Widget _juliaEditor(ColorScheme scheme) => AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    child: widget.selectedFractal != FractalType.julia
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Card(
              margin: EdgeInsets.zero,
              color: scheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('JULIA CONSTANT (C)', scheme),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _juliaField('Real', _juliaCReController),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _juliaField('Imaginary', _juliaCImController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _updateJulia,
                        child: const Text('UPDATE'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
  );

  Widget _juliaField(String label, TextEditingController controller) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      const SizedBox(height: 5),
      Row(
        children: [
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            tooltip: 'Decrease $label',
            onPressed: () => _adjustJulia(controller, -_juliaStep),
            icon: const Icon(Icons.remove, size: 16),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filledTonal(
            visualDensity: VisualDensity.compact,
            tooltip: 'Increase $label',
            onPressed: () => _adjustJulia(controller, _juliaStep),
            icon: const Icon(Icons.add, size: 16),
          ),
        ],
      ),
    ],
  );

  Widget _iterations(ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          _label('ITERATIONS:', scheme),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: ShapeDecoration(
              color: scheme.primaryContainer,
              shape: const StadiumBorder(),
            ),
            child: Text(
              '${widget.maxIterations}',
              style: TextStyle(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      Slider(
        min: 0,
        max: (_iterationSteps.length - 1).toDouble(),
        divisions: _iterationSteps.length - 1,
        value: _iterationIndex.toDouble(),
        onChanged: (value) =>
            widget.onMaxIterationsChanged(_iterationSteps[value.round()]),
        padding: const EdgeInsets.only(top: 8),
      ),
    ],
  );

  Widget _palettes() => Column(
    children: ColorPalette.values.map((palette) {
      final selected = palette == widget.selectedPalette;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          selected: selected,
          button: true,
          label: '${palette.label} color palette',
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => widget.onPaletteChanged(palette),
            child: Ink(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: _paletteGradient(palette),
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: .16),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      palette.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 5,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected) const Icon(Icons.check, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _performanceHud() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Performance HUD'),
    value: widget.showPerformanceHud,
    onChanged: widget.onPerformanceHudChanged,
  );

  Widget _actions() => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: widget.onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: widget.onSaveImage,
          icon: const Icon(Icons.download),
          label: const Text('Save'),
        ),
      ),
    ],
  );

  Widget _exitButton(ColorScheme scheme) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: SystemNavigator.pop,
      icon: const Icon(Icons.exit_to_app),
      label: const Text('Exit Application'),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: .65)),
      ),
    ),
  );
}
