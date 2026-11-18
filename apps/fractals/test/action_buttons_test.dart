import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(
  WidgetTester tester, {
  required VoidCallback onReset,
  required VoidCallback onSaveImage,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        drawer: HamburgerMenu(
          selectedFractal: FractalType.mandelbrot,
          selectedPalette: ColorPalette.inferno,
          maxIterations: 300,
          juliaCRe: -0.5125,
          juliaCIm: 0.5213,
          showPerformanceHud: true,
          onFractalChanged: (_) {},
          onPaletteChanged: (_) {},
          onMaxIterationsChanged: (_) {},
          onJuliaChanged: (_, _) {},
          onPerformanceHudChanged: (_) {},
          onReset: onReset,
          onSaveImage: onSaveImage,
        ),
        body: const SizedBox.shrink(),
      ),
    ),
  );

  scaffoldKey.currentState!.openDrawer();
  await tester.pumpAndSettle();
  await tester.drag(find.byType(ListView), const Offset(0, -1000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Reset button is present in the Hamburger menu', (tester) async {
    await _openHamburgerMenu(tester, onReset: () {}, onSaveImage: () {});

    expect(find.widgetWithText(OutlinedButton, 'Reset'), findsOneWidget);
  });

  testWidgets('Reset button invokes its callback when tapped', (tester) async {
    var resetCalled = false;
    await _openHamburgerMenu(
      tester,
      onReset: () => resetCalled = true,
      onSaveImage: () {},
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pump();

    expect(resetCalled, isTrue);
  });

  testWidgets('Save button is present in the Hamburger menu', (tester) async {
    await _openHamburgerMenu(tester, onReset: () {}, onSaveImage: () {});

    expect(find.widgetWithText(OutlinedButton, 'Save'), findsOneWidget);
  });

  testWidgets('Save button invokes its callback when tapped', (tester) async {
    var saveCalled = false;
    await _openHamburgerMenu(
      tester,
      onReset: () {},
      onSaveImage: () => saveCalled = true,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pump();

    expect(saveCalled, isTrue);
  });
}
