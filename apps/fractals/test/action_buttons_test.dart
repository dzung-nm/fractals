import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals/main.dart' as app;
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

  // Scroll down to ensure all palette options are visible
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

  testWidgets('Reset button closes the Hamburger menu', (tester) async {
    await _openHamburgerMenu(tester, onReset: () {}, onSaveImage: () {});
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scaffoldState.isDrawerOpen, isFalse);
  });

  testWidgets('Reset button replaces the FractalWidget key', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: app.HomeScreen()));
    final oldKey = tester.widget<FractalWidget>(find.byType(FractalWidget)).key;

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    scaffoldState.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(scaffoldState.isDrawerOpen, isTrue);
    await tester.ensureVisible(find.text('Reset'));
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
    await tester.pump();

    final newKey = tester.widget<FractalWidget>(find.byType(FractalWidget)).key;
    expect(newKey, isNot(same(oldKey)));
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

  // This test ensures that tapping the "Save" button closes the Hamburger menu, 
  // similar to the "Reset" button behavior. This behavior allows users to see 
  // the snackbar notification after saving an image
  testWidgets('Save button closes the Hamburger menu', (tester) async {
    await _openHamburgerMenu(tester, onReset: () {}, onSaveImage: () {});
    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scaffoldState.isDrawerOpen, isFalse);
  });
}
