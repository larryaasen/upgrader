// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';

import 'test_utils.dart';

void main() {
  setUp(() async {});

  testWidgets(
    'test UpgradeAlert prompt message is visible',
    (WidgetTester tester) async {
      final upgrader = Upgrader(
        debugDisplayAlways: true,
        upgraderOS: MockUpgraderOS(ios: true),
      )
        ..installPackageInfo(
          packageInfo: PackageInfo(
              appName: 'Upgrader',
              packageName: 'com.larryaasen.upgrader',
              version: '0.9.9',
              buildNumber: '400'),
        )
        ..initialize();

      await tester.pumpAndSettle();
      await tester.pumpWidget(wrapper(UpgradeAlert(upgrader: upgrader)));
      await tester.pumpAndSettle();

      expect(
        find.text(UpgraderMessages().message(UpgraderMessage.prompt)!),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'test UpgradeAlert prompt message is not visible',
    (WidgetTester tester) async {
      final upgrader = Upgrader(
        debugDisplayAlways: true,
        upgraderOS: MockUpgraderOS(ios: true),
      )
        ..installPackageInfo(
          packageInfo: PackageInfo(
              appName: 'Upgrader',
              packageName: 'com.larryaasen.upgrader',
              version: '0.9.9',
              buildNumber: '400'),
        )
        ..initialize();

      await tester.pumpAndSettle();
      await tester.pumpWidget(
        wrapper(
          UpgradeAlert(
            upgrader: upgrader,
            showPrompt: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(UpgraderMessages().message(UpgraderMessage.prompt)!),
        findsNothing,
      );
    },
  );
}
