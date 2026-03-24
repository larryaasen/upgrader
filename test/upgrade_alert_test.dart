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
      final delayDuration = 2;
      final laterTitle =
          UpgraderMessages().message(UpgraderMessage.buttonTitleLater)!;

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
            child: child,
          ),
          home: _SplashScreen(
            Duration(seconds: delayDuration),
          ),
        ),
      );
      await tester.pump(Duration(seconds: delayDuration - 1));
      await tester.pumpAndSettle();

      expect(find.byType(_SplashScreen), findsOneWidget);
      expect(find.byType(_HomeScreen), findsNothing);
      expect(find.text(laterTitle), findsOneWidget,
          reason: 'UpgradeAlert should be visible before the route is pushed');

      await tester.pump(Duration(seconds: delayDuration));
      await tester.pumpAndSettle();

      expect(find.byType(_HomeScreen), findsOneWidget);
      expect(find.byType(_SplashScreen), findsNothing);

      await tester.tap(find.text(laterTitle));
      await tester.pumpAndSettle();

      expect(laterTapped, true);
    },
  );
}

class _SplashScreen extends StatefulWidget {
  final Duration delay;
  const _SplashScreen(this.delay);

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const _HomeScreen(),
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

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('home'),
      ),
    );
  }
}
