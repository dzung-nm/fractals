import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fractals/fractal_widget.dart';
import 'package:fractals/hamburger_menu.dart';
import 'package:fractals_gen/fractals_gen.dart';

Future<void> _openHamburgerMenu(WidgetTester tester) async {
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('exit button closes desktop app and is hidden on web', (
    tester,
  ) async {
    await _openHamburgerMenu(tester);

    if (kIsWeb) {
      expect(
        find.widgetWithText(OutlinedButton, 'Exit Application'),
        findsNothing,
      );
      return;
    }

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

    final drawerFinder = find.byType(Drawer);

    // Verify that the drawer is present in the widget tree
    expect(drawerFinder, findsOneWidget);

    // Verify that the exit button is present in the drawer
    final exitButton = find.widgetWithText(OutlinedButton, 'Exit Application');
    expect(exitButton, findsOneWidget);

    // Verify that the exit button is positioned at the bottom of the drawer
    final drawerRect = tester.getRect(drawerFinder);
    final exitButtonRect = tester.getRect(exitButton);
    expect(exitButtonRect.bottom, closeTo(drawerRect.bottom - 12, 0.1));

    // Simulate a tap on the exit button and verify that the platform method is called
    await tester.tap(exitButton);
    await tester.pump();

    expect(
      platformCalls.map((call) => call.method),
      contains('System.exitApplication'),
    );
  }, variant: TargetPlatformVariant.desktop());

  testWidgets(
    'exit button requests application exit on Windows',
    (tester) async {
      await _openHamburgerMenu(tester);

      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return <String, Object?>{'response': 'exit'};
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.tap(find.widgetWithText(OutlinedButton, 'Exit Application'));
      await tester.pump();

      expect(platformCalls, hasLength(1));
      expect(platformCalls.single.method, 'System.exitApplication');
      expect(platformCalls.single.arguments, {
        'type': 'required',
        'exitCode': 0,
      });
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.windows,
    }),
  );

  testWidgets('exit button is hidden on web', (tester) async {
    await _openHamburgerMenu(tester);
    if (kIsWeb) {
      expect(
        find.widgetWithText(OutlinedButton, 'Exit Application'),
        findsNothing,
      );
    }
  }, variant: TargetPlatformVariant.desktop());

  testWidgets(
    'exit button is hidden on Android and iOS',
    (tester) async {
      await _openHamburgerMenu(tester);
      expect(
        find.widgetWithText(OutlinedButton, 'Exit Application'),
        findsNothing,
      );
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );
}
