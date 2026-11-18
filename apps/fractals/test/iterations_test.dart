import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(
  WidgetTester tester, {
  required int maxIterations,
  required ValueChanged<int> onMaxIterationsChanged,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        drawer: HamburgerMenu(
          selectedFractal: FractalType.mandelbrot,
          selectedPalette: ColorPalette.inferno,
          maxIterations: maxIterations,
          juliaCRe: -0.5125,
          juliaCIm: 0.5213,
          showPerformanceHud: true,
          onFractalChanged: (_) {},
          onPaletteChanged: (_) {},
          onMaxIterationsChanged: onMaxIterationsChanged,
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
  
  await tester.ensureVisible(find.byType(Slider));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('iterations slider displays the current max iteration value', (
    tester,
  ) async {
    await _openHamburgerMenu(
      tester,
      maxIterations: 300,
      onMaxIterationsChanged: (_) {},
    );

    expect(find.text('300'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 2);
  });

  testWidgets('iterations slider reports the selected iteration value', (
    tester,
  ) async {
    int? changedIterations;
    await _openHamburgerMenu(
      tester,
      maxIterations: 300,
      onMaxIterationsChanged: (value) => changedIterations = value,
    );

    final sliderFinder = find.byType(Slider);
    final sliderSize = tester.getSize(sliderFinder);
    await tester.tapAt(
      tester.getTopLeft(sliderFinder) +
          Offset(sliderSize.width - 8, sliderSize.height / 2),
    );
    await tester.pump();

    expect(changedIterations, 700);
  });
}
