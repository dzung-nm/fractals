import 'package:flutter/material.dart';

import 'core/color_palette.dart';
import 'fractal_widget.dart';

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

  GlobalKey<FractalWidgetState> _fractalKey = GlobalKey<FractalWidgetState>();

  Future<void> _saveCurrentImage() async {
    await _fractalKey.currentState?.saveToImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<FractalType>(
            value: _fractalType,
            dropdownColor: Colors.blue.shade700,
            iconEnabledColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            items: FractalType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (type) {
              if (type == null || type == _fractalType) return;
              setState(() {
                _fractalType = type;
                _fractalKey = GlobalKey<FractalWidgetState>();
              });
            },
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _palette = ColorPalette.inferno;
                _fractalKey = GlobalKey<FractalWidgetState>();
              });
            },
          ),
          IconButton(
            tooltip: 'Save image as PNG',
            icon: const Icon(Icons.save_alt),
            onPressed: _saveCurrentImage,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ColorPalette>(
                value: _palette,
                dropdownColor: Colors.blue.shade700,
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                items: ColorPalette.values
                    .map(
                      (palette) => DropdownMenuItem(
                        value: palette,
                        child: Text(palette.label),
                      ),
                    )
                    .toList(),
                onChanged: (palette) {
                  if (palette == null || palette == _palette) return;
                  setState(() => _palette = palette);
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.floor();
          final height = constraints.maxHeight.floor();

          if (width <= 0 || height <= 0) {
            return const SizedBox.shrink();
          }

          return FractalWidget(
            key: _fractalKey,
            width: width,
            height: height,
            palette: _palette,
            fractalType: _fractalType,
          );
        },
      ),
    );
  }
}
