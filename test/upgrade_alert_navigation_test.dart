// Copyright (c) 2026 Larry Aasen. All rights reserved.

// Tests for how UpgradeAlert interacts with navigation: dialog dismissal,
// system back, custom dialogs, and placement in MaterialApp.builder.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_itunes_client.dart';

/// Creates an [Upgrader] that always displays the alert. It is not
/// initialized here so that [UpgradeAlert] initializes it after the app's
/// navigator has been mounted.
Upgrader _upgrader() => Upgrader(
      client: MockITunesSearchClient.setupMockClient(),
      debugDisplayAlways: true,
      upgraderOS: MockUpgraderOS(ios: true),
    )..installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'),
      );

/// Pumps until the version check has completed and the dialog is shown.
Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// Wraps the whole app with [alert] using [MaterialApp.builder].
Widget _builderApp({
  required GlobalKey<NavigatorState> navigatorKey,
  required Widget Function(Widget? child) alert,
  required Widget home,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    builder: (context, child) => alert(child),
    home: home,
  );
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: onTap,
          child: const Text('home button'),
        ),
      ),
    );
  }
}

class _CustomUpgradeAlert extends UpgradeAlert {
  _CustomUpgradeAlert({super.upgrader, super.navigatorKey, super.child});

  @override
  UpgradeAlertState createState() => _CustomUpgradeAlertState();
}

class _CustomUpgradeAlertState extends UpgradeAlertState {
  @override
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('custom title'),
        actions: [
          TextButton(
            onPressed: () => popNavigator(context),
            child: const Text('custom close'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  final laterTitle =
      UpgraderMessages().message(UpgraderMessage.buttonTitleLater)!;
  final ignoreTitle =
      UpgraderMessages().message(UpgraderMessage.buttonTitleIgnore)!;

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder leaves the app usable after a barrier tap',
    (WidgetTester tester) async {
      var homeTaps = 0;
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_builderApp(
        navigatorKey: navigatorKey,
        alert: (child) => UpgradeAlert(
          upgrader: _upgrader(),
          navigatorKey: navigatorKey,
          barrierDismissible: true,
          child: child,
        ),
        home: _HomeScreen(onTap: () => homeTaps++),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap the barrier outside of the dialog.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('home button'), warnIfMissed: false);
      await tester.pump();
      expect(homeTaps, 1,
          reason: 'the app should accept taps after the dialog is dismissed');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder handles system back',
    (WidgetTester tester) async {
      var shouldPopScopeCalled = false;
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_builderApp(
        navigatorKey: navigatorKey,
        alert: (child) => UpgradeAlert(
          upgrader: _upgrader(),
          navigatorKey: navigatorKey,
          shouldPopScope: () {
            shouldPopScopeCalled = true;
            return false;
          },
          child: child,
        ),
        home: const _HomeScreen(),
      ));

      // Push a route before the dialog is shown, so system back has a route
      // it could pop.
      navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (context) => const Text('second screen')));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      expect(shouldPopScopeCalled, true,
          reason: 'system back should be handled by the dialog');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('second screen'), findsOneWidget,
          reason: 'system back should not pop the route under the dialog');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder with an overridden showTheDialog',
    (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_builderApp(
        navigatorKey: navigatorKey,
        alert: (child) => _CustomUpgradeAlert(
          upgrader: _upgrader(),
          navigatorKey: navigatorKey,
          child: child,
        ),
        home: const _HomeScreen(),
      ));
      await _settle(tester);
      expect(find.text('custom title'), findsOneWidget);

      await tester.tap(find.text('custom close'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('custom title'), findsNothing,
          reason: 'the custom dialog should receive taps');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder closes on later with debugDisplayAlways',
    (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_builderApp(
        navigatorKey: navigatorKey,
        alert: (child) => UpgradeAlert(
          upgrader: _upgrader(),
          navigatorKey: navigatorKey,
          child: child,
        ),
        home: const _HomeScreen(),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(laterTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'test UpgradeAlert closes on later with debugDisplayAlways',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UpgradeAlert(
          upgrader: _upgrader(),
          child: const _HomeScreen(),
        ),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(laterTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'test UpgradeAlert closes on ignore with debugDisplayAlways',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: UpgradeAlert(
          upgrader: _upgrader(),
          child: const _HomeScreen(),
        ),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(ignoreTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
}
