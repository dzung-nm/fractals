import 'package:flutter/material.dart';
import 'package:fractals_gen/fractals_gen.dart';

import 'fractal_widget.dart';
import 'hamburger_menu.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ColorPalette _palette = ColorPalette.inferno;
  FractalType _fractalType = FractalType.mandelbrot;
  int _maxIterations = 300;
  double _juliaCRe = -0.5125;
  double _juliaCIm = 0.5213;
  bool _showPerformanceHud = true;

  GlobalKey<FractalWidgetState> _fractalKey = GlobalKey<FractalWidgetState>();

  Future<void> _saveCurrentImage() async {
    await _fractalKey.currentState?.saveToImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: HamburgerMenu(
        selectedFractal: _fractalType,
        selectedPalette: _palette,
        maxIterations: _maxIterations,
        onFractalChanged: (type) {
          if (type == _fractalType) return;
          setState(() {
            _fractalType = type;
            _fractalKey = GlobalKey<FractalWidgetState>();
          });
        },
        onPaletteChanged: (palette) {
          if (palette == _palette) return;
          setState(() => _palette = palette);
        },
        onMaxIterationsChanged: (iterations) {
          setState(() => _maxIterations = iterations);
        },
        juliaCRe: _juliaCRe,
        juliaCIm: _juliaCIm,
        showPerformanceHud: _showPerformanceHud,
        onPerformanceHudChanged: (show) {
          setState(() => _showPerformanceHud = show);
        },
        onJuliaChanged: (real, imaginary) {
          setState(() {
            _juliaCRe = real;
            _juliaCIm = imaginary;
          });
        },
        onReset: () {
          setState(() {
            _fractalKey = GlobalKey<FractalWidgetState>();
          });
        },
        onSaveImage: _saveCurrentImage,
      ),
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          final height = constraints.maxHeight.floor();

          if (width <= 0 || height <= 0) {
            return const SizedBox.shrink();
          }

          return Stack(
            children: [
              Positioned.fill(
                child: FractalWidget(
                  key: _fractalKey,
                  width: width,
                  height: height,
                  palette: _palette,
                  fractalType: _fractalType,
                  maxIterations: _maxIterations,
                  juliaCRe: _juliaCRe,
                  juliaCIm: _juliaCIm,
                  showPerformanceHud: _showPerformanceHud,
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  color: Colors.white.withValues(alpha: 0.5),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
