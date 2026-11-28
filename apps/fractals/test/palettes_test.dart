import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(
  WidgetTester tester, {
  required ColorPalette selectedPalette,
  required ValueChanged<ColorPalette> onPaletteChanged,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        drawer: HamburgerMenu(
          selectedFractal: FractalType.mandelbrot,
          selectedPalette: selectedPalette,
          maxIterations: 300,
          juliaCRe: -0.5125,
          juliaCIm: 0.5213,
          showPerformanceHud: true,
          onFractalChanged: (_) {},
          onPaletteChanged: onPaletteChanged,
          onMaxIterationsChanged: (_) {},
          onJuliaChanged: (_, _) {},
          onPerformanceHudChanged: (_) {},
          onReset: () {},
          onSaveImage: () {},
        ),
        body: const SizedBox.shrink(),
      ),
    ),
  );

  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();

  // Scroll down to ensure all palette options are visible
  await tester.drag(find.byType(ListView), const Offset(0, -1000));

  await tester.ensureVisible(find.text('Aurora'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all palettes are available in the Hamburger menu', (
    tester,
  ) async {
    await _openHamburgerMenu(
      tester,
      selectedPalette: ColorPalette.inferno,
      onPaletteChanged: (_) {},
    );

    expect(find.text('Inferno'), findsOneWidget);
    expect(find.text('Ocean'), findsOneWidget);
    expect(find.text('Aurora'), findsOneWidget);
  });

  testWidgets('selecting a palette invokes the callback with that palette', (
    tester,
  ) async {
    ColorPalette? changedPalette;
    await _openHamburgerMenu(
      tester,
      selectedPalette: ColorPalette.inferno,
      onPaletteChanged: (palette) => changedPalette = palette,
    );

    await tester.ensureVisible(find.text('Ocean'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocean'));
    await tester.pump();

    expect(changedPalette, ColorPalette.ocean);
  });
}
