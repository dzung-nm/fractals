import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(
  WidgetTester tester, {
  required FractalType selectedFractal,
  required void Function(double real, double imaginary) onJuliaChanged,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        drawer: HamburgerMenu(
          selectedFractal: selectedFractal,
          selectedPalette: ColorPalette.inferno,
          maxIterations: 300,
          juliaCRe: -0.5125,
          juliaCIm: 0.5213,
          showPerformanceHud: true,
          onFractalChanged: (_) {},
          onPaletteChanged: (_) {},
          onMaxIterationsChanged: (_) {},
          onJuliaChanged: onJuliaChanged,
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
}

void main() {
  testWidgets('Julia editor is only shown for the Julia fractal', (
    tester,
  ) async {
    await _openHamburgerMenu(
      tester,
      selectedFractal: FractalType.mandelbrot,
      onJuliaChanged: (_, _) {},
    );

    expect(
      tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState,
      CrossFadeState.showFirst,
    );

    await _openHamburgerMenu(
      tester,
      selectedFractal: FractalType.julia,
      onJuliaChanged: (_, _) {},
    );

    expect(
      tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState,
      CrossFadeState.showSecond,
    );
  });

  testWidgets('Julia editor displays its values in fixed-width fields', (
    tester,
  ) async {
    await _openHamburgerMenu(
      tester,
      selectedFractal: FractalType.julia,
      onJuliaChanged: (_, _) {},
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields[0].controller!.text, '-0.5125');
    expect(fields[1].controller!.text, '0.5213');
    expect(tester.getSize(find.byType(TextField).first).width, 100);
    expect(tester.getSize(find.byType(TextField).last).width, 100);
  });

  testWidgets('Update applies valid Julia constant values', (tester) async {
    double? updatedReal;
    double? updatedImaginary;
    await _openHamburgerMenu(
      tester,
      selectedFractal: FractalType.julia,
      onJuliaChanged: (real, imaginary) {
        updatedReal = real;
        updatedImaginary = imaginary;
      },
    );

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '-0.25');
    await tester.enterText(fields.last, '0.75');
    await tester.tap(find.text('UPDATE'));
    await tester.pump();

    expect(updatedReal, -0.25);
    expect(updatedImaginary, 0.75);
  });

  testWidgets('Update shows an error for invalid Julia constant values', (
    tester,
  ) async {
    var updateCalled = false;
    await _openHamburgerMenu(
      tester,
      selectedFractal: FractalType.julia,
      onJuliaChanged: (_, _) => updateCalled = true,
    );

    await tester.enterText(find.byType(TextField).first, '-');
    await tester.tap(find.text('UPDATE'));
    await tester.pump();

    expect(updateCalled, isFalse);
    expect(find.text('Enter valid real and imaginary values.'), findsOneWidget);
  });
}
