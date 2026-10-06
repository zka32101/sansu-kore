import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sansu_kore/widgets/startup_splash.dart';

void main() {
  testWidgets('起動画面の下部に組織ロゴが出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartupSplash()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Your Wish'), findsOneWidget);
    final y = tester.getCenter(find.byType(Image)).dy;
    expect(y, greaterThan(tester.view.physicalSize.height / tester.view.devicePixelRatio / 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('組織ロゴフッターは画面下部に出る', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Align(alignment: Alignment.bottomCenter, child: OrgLogoFooter()),
      ),
    ));
    expect(find.bySemanticsLabel('Your Wish'), findsOneWidget);
    final y = tester.getCenter(find.byType(Image)).dy;
    expect(y, greaterThan(tester.view.physicalSize.height / tester.view.devicePixelRatio / 2));
  });
}
