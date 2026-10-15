// Copyright (c) 2026 Larry Aasen. All rights reserved.

// Tests for how UpgradeAlert interacts with navigation: dialog dismissal,
// system back, custom dialogs, and placement in MaterialApp.builder.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

/// Sends a system back through the binding, as Android does.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Returns whether `SystemNavigator.pop` (exit the app) has been called.
bool Function() _trackSystemNavigatorPop(WidgetTester tester) {
  var popped = false;
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemNavigator.pop') popped = true;
    return null;
  });
  addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return () => popped;
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

class _NoDialogUpgradeAlert extends UpgradeAlert {
  _NoDialogUpgradeAlert({super.upgrader, super.child});

  @override
  UpgradeAlertState createState() => _NoDialogUpgradeAlertState();
}

class _NoDialogUpgradeAlertState extends UpgradeAlertState {
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
    // A custom presentation that opens no dialog.
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

      await _systemBack(tester);

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

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder without a navigatorKey blocks system back',
    (WidgetTester tester) async {
      final systemNavigatorPopped = _trackSystemNavigatorPop(tester);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          shouldPopScope: () => false,
          child: child,
        ),
        home: const _HomeScreen(),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await _systemBack(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(systemNavigatorPopped(), false,
          reason: 'system back should be handled by the dialog, not exit');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder without a navigatorKey closes on system back',
    (WidgetTester tester) async {
      var homeTaps = 0;
      final systemNavigatorPopped = _trackSystemNavigatorPop(tester);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          shouldPopScope: () => true,
          child: child,
        ),
        home: _HomeScreen(onTap: () => homeTaps++),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await _systemBack(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(systemNavigatorPopped(), false);

      await tester.tap(find.text('home button'), warnIfMissed: false);
      await tester.pump();
      expect(homeTaps, 1,
          reason: 'the app should accept taps after the dialog is dismissed');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.router builder handles system back',
    (WidgetTester tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (context, state) => const _HomeScreen()),
        GoRoute(
            path: '/second',
            builder: (context, state) => const Text('second screen')),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          shouldPopScope: () => false,
          child: child,
        ),
      ));
      router.push('/second');
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await _systemBack(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('second screen'), findsOneWidget,
          reason: 'system back should not pop the route under the dialog');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder without a navigatorKey leaves the app usable after a barrier tap',
    (WidgetTester tester) async {
      var homeTaps = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          barrierDismissible: true,
          child: child,
        ),
        home: _HomeScreen(onTap: () => homeTaps++),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await tester.tap(find.text('home button'), warnIfMissed: false);
      await tester.pump();
      expect(homeTaps, 1);
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder without a navigatorKey blocks back on the app navigator',
    (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          shouldPopScope: () => false,
          child: child,
        ),
        home: const _HomeScreen(),
      ));
      navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (context) => const Text('second screen')));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await _systemBack(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('second screen'), findsOneWidget,
          reason: 'system back should not pop the route under the dialog');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder without a navigatorKey closes on later with debugDisplayAlways',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            UpgradeAlert(upgrader: _upgrader(), child: child),
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
    'test UpgradeAlert in MaterialApp.builder with a showTheDialog override that opens no dialog',
    (WidgetTester tester) async {
      var homeTaps = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) =>
            _NoDialogUpgradeAlert(upgrader: _upgrader(), child: child),
        home: _HomeScreen(onTap: () => homeTaps++),
      ));
      await _settle(tester);

      await tester.tap(find.text('home button'), warnIfMissed: false);
      await tester.pump();
      expect(homeTaps, 1);
    },
  );

  for (final withNavigatorKey in [true, false]) {
    testWidgets(
      'test UpgradeAlert in MaterialApp.builder stays above a later pushed route (navigatorKey: $withNavigatorKey)',
      (WidgetTester tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => UpgradeAlert(
            upgrader: _upgrader(),
            navigatorKey: withNavigatorKey ? navigatorKey : null,
            child: child,
          ),
          home: const _HomeScreen(),
        ));
        await _settle(tester);
        expect(find.byType(AlertDialog), findsOneWidget);

        navigatorKey.currentState!.push(MaterialPageRoute<void>(
            builder: (context) => const Scaffold(body: Text('second'))));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);

        await tester.tap(find.text(laterTitle));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('second'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder does not let Android back close the app after the dialog closes',
    (WidgetTester tester) async {
      final frameworkHandlesBack = <bool>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
          frameworkHandlesBack.add(call.arguments as bool);
        }
        return null;
      });
      addTearDown(() =>
          messenger.setMockMethodCallHandler(SystemChannels.platform, null));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) =>
            UpgradeAlert(upgrader: _upgrader(), child: child),
        home: const _HomeScreen(),
      ));
      navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (context) => const Text('second screen')));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text(laterTitle));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      expect(frameworkHandlesBack, isNotEmpty);
      expect(frameworkHandlesBack.last, true,
          reason: 'the app still has a page to go back to, so back must not '
              'close the app');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.builder blocks back on a route pushed after the dialog',
    (WidgetTester tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          shouldPopScope: () => false,
          child: child,
        ),
        home: const _HomeScreen(),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (context) => const Text('second screen')));
      await tester.pumpAndSettle();

      await _systemBack(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('second screen'), findsOneWidget,
          reason: 'back should be blocked on the newly pushed route too');
    },
  );

  testWidgets(
    'test UpgradeAlert in MaterialApp.router with a navigatorKey stays above go()',
    (WidgetTester tester) async {
      final router = GoRouter(initialLocation: '/splash', routes: [
        GoRoute(
            path: '/splash',
            builder: (context, state) => const Text('splash screen')),
        GoRoute(
            path: '/home', builder: (context, state) => const _HomeScreen()),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => UpgradeAlert(
          upgrader: _upgrader(),
          navigatorKey: router.routerDelegate.navigatorKey,
          child: child,
        ),
      ));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      router.go('/home');
      await tester.pumpAndSettle();
      expect(find.text('home button'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'replacing the page under the dialog should not dismiss it');
    },
  );
}
