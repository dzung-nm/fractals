import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exit button requests the platform to close the application', (
    tester,
  ) async {
    final platformCalls = <MethodCall>[];

    // Mock the platform channel to capture method calls made to it
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );

    // Reset the mock handler after the test to avoid affecting other tests
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

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
            onReset: () {},
            onSaveImage: () {},
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    final drawerFinder = find.byType(Drawer);

    // Verify that the drawer is present in the widget tree
    expect(drawerFinder, findsOneWidget);

    // Verify that the exit button is present in the drawer
    final exitButton = find.widgetWithText(OutlinedButton, 'Exit Application');
    expect(exitButton, findsOneWidget);

    // Verify that the exit button is positioned at the bottom of the drawer
    final drawerRect = tester.getRect(drawerFinder);
    final exitButtonRect = tester.getRect(exitButton);
    expect(
      exitButtonRect.bottom,
      closeTo(drawerRect.bottom - 12, 0.1),
    );

    // Simulate a tap on the exit button and verify that the platform method is called
    await tester.tap(exitButton);
    await tester.pump();

    expect(
      platformCalls.map((call) => call.method),
      contains('SystemNavigator.pop'),
    );
  });
}
