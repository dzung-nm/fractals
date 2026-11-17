import 'package:flutter/material.dart';
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

    expect(find.byType(Drawer), findsOneWidget);

    // The menu content is scrollable, so scroll it down before looking for the
    // exit button in the lower section of the list.
    final scrollable = find
        .descendant(
          of: find.byType(HamburgerMenu),
          matching: find.byType(Scrollable),
        )
        .last;

    await tester.drag(scrollable, const Offset(0, -600));
    await tester.pumpAndSettle();

    final exitButton = find.widgetWithText(OutlinedButton, 'Exit Application');

    expect(exitButton, findsOneWidget);
    expect(
      find.descendant(of: exitButton, matching: find.byIcon(Icons.exit_to_app)),
      findsOneWidget,
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
