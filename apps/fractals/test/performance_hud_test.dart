import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(
  WidgetTester tester, {
  required bool showPerformanceHud,
  required ValueChanged<bool> onPerformanceHudChanged,
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
          showPerformanceHud: showPerformanceHud,
          onFractalChanged: (_) {},
          onPaletteChanged: (_) {},
          onMaxIterationsChanged: (_) {},
          onJuliaChanged: (_, _) {},
          onPerformanceHudChanged: onPerformanceHudChanged,
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
  
  await tester.ensureVisible(find.text('Performance HUD'));
  await tester.pumpAndSettle();
}

Future<void> _pumpFractalWidget(
  WidgetTester tester, {
  required bool showPerformanceHud,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: FractalWidget(
        width: 100,
        height: 100,
        palette: ColorPalette.inferno,
        fractalType: FractalType.mandelbrot,
        maxIterations: 10,
        showPerformanceHud: showPerformanceHud,
      ),
    ),
  );
}

void main() {
  testWidgets('Performance HUD switch reflects its initial value', (
    tester,
  ) async {
    await _openHamburgerMenu(
      tester,
      showPerformanceHud: true,
      onPerformanceHudChanged: (_) {},
    );

    final switchFinder = find.widgetWithText(SwitchListTile, 'Performance HUD');
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
  });

  testWidgets('Performance HUD switch reports its updated value', (
    tester,
  ) async {
    bool? updatedValue;
    await _openHamburgerMenu(
      tester,
      showPerformanceHud: true,
      onPerformanceHudChanged: (value) => updatedValue = value,
    );

    await tester.tap(find.widgetWithText(SwitchListTile, 'Performance HUD'));
    await tester.pump();

    expect(updatedValue, isFalse);
  });

  testWidgets('FractalWidget displays the Performance HUD when enabled', (
    tester,
  ) async {
    await _pumpFractalWidget(tester, showPerformanceHud: true);

    final hudFinder = find.byKey(const ValueKey('performance_hud'));
    expect(hudFinder, findsOneWidget);
    expect(tester.widget(hudFinder), isA<DecoratedBox>());
  });

  testWidgets('FractalWidget hides the Performance HUD when disabled', (
    tester,
  ) async {
    await _pumpFractalWidget(tester, showPerformanceHud: false);

    expect(find.byKey(const ValueKey('performance_hud')), findsNothing);
  });
}
