// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
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

  testWidgets(
    'test UpgradeAlert stays above a later pushed route',
    (WidgetTester tester) async {
      var laterTapped = false;
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

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => UpgradeAlert(
            upgrader: upgrader,
            onLater: () {
              laterTapped = true;
              return true;
            },
            child: child ?? const SizedBox.shrink(),
          ),
          home: const _DelayedPushScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);

      await tester.tap(
        find.text(
          UpgraderMessages().message(UpgraderMessage.buttonTitleLater)!,
        ),
      );
      await tester.pumpAndSettle();

      expect(laterTapped, true);
    },
  );
}

class _DelayedPushScreen extends StatefulWidget {
  const _DelayedPushScreen();

  @override
  State<_DelayedPushScreen> createState() => _DelayedPushScreenState();
}

class _DelayedPushScreenState extends State<_DelayedPushScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const Scaffold(
            body: Center(
              child: Text('home'),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('splash'),
      ),
    );
  }
}
