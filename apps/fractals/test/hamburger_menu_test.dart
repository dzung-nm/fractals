import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:fractals/main.dart' as app;

void main() {
  testWidgets('tapping the hamburger icon opens the menu', (tester) async {
    tester.view.physicalSize = const Size(400, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: app.HomeScreen()));

    final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffoldState.isDrawerOpen, isFalse);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(scaffoldState.isDrawerOpen, isTrue);
    expect(find.text('FRACTAL TYPE'), findsOneWidget);
  });
}
