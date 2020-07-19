/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'mockclient.dart';

void main() {
  SharedPreferences preferences;

  const sharedPrefsChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  const kEmptyPreferences = <String, dynamic>{};

  setUp(() async {
    Upgrader.resetSingleton();

    // This idea to mock the shared preferences taken from:
    /// https://github.com/flutter/plugins/blob/master/packages/shared_preferences/test/shared_preferences_test.dart
    sharedPrefsChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return kEmptyPreferences;
      }
      return null;
    });
    preferences = await SharedPreferences.getInstance();
    await Upgrader().clearSavedSettings();
  });

  tearDown(() async {
    await preferences.clear();
  });

  testWidgets('test Upgrader class', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;

    expect(tester.takeException(), null);
    await tester.pumpAndSettle();
    try {
      expect(upgrader.appName(), 'Upgrader');
    } catch (e) {
      expect(e, upgrader.notInitializedExceptionMessage);
    }

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    // Calling initialize() a second time should do nothing
    await upgrader.initialize();

    expect(upgrader.appName(), 'Upgrader');
    expect(upgrader.currentAppStoreVersion(), '5.6');
    expect(upgrader.currentInstalledVersion(), '1.9.9');
    expect(upgrader.isUpdateAvailable(), true);

    upgrader.installAppStoreVersion('1.2.3');
    expect(upgrader.currentAppStoreVersion(), '1.2.3');
  });

  testWidgets('test installAppStoreListingURL', (WidgetTester tester) async {
    final upgrader = Upgrader();
    upgrader.installAppStoreListingURL(
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');

    expect(upgrader.currentAppStoreListingURL(),
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');
  });

  testWidgets('test UpgradeWidget', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isUpdateAvailable(), true);
    expect(upgrader.isTooSoon(), false);

    expect(upgrader.messages, isNotNull);

    expect(upgrader.messages.buttonTitleIgnore, 'IGNORE');
    expect(upgrader.messages.buttonTitleLater, 'LATER');
    expect(upgrader.messages.buttonTitleUpdate, 'UPDATE NOW');

    upgrader.messages = MyUpgraderMessages();

    expect(upgrader.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader.messages.buttonTitleLater, 'bbb');
    expect(upgrader.messages.buttonTitleUpdate, 'ccc');

    await tester.pumpWidget(_MyWidget());

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.messages.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.messages.prompt), findsOneWidget);
    expect(find.byType(FlatButton), findsNWidgets(3));
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);

    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  });

  testWidgets('test UpgradeWidget ignore', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget());

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  });

  testWidgets('test UpgradeWidget later', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget());

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  });

  testWidgets('test UpgradeWidget Card upgrade', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    expect(upgrader.messages, isNotNull);

    var called = false;
    var notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
  });

  testWidgets('test UpgradeWidget Card ignore', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
  });

  testWidgets('test UpgradeWidget Card later', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
  });

  testWidgets('test upgrader minAppVersion', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;
    upgrader.minAppVersion = '1.0.0';

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    expect(upgrader.isTooSoon(), false);
    upgrader.minAppVersion = '0.5.0';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0';
    expect(upgrader.belowMinAppVersion(), true);
    upgrader.minAppVersion = null;
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = 'empty';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0';

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);
  });

  testWidgets('test UpgradeWidget unknown app', (WidgetTester tester) async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;
    upgrader.countryCode = 'IT';

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'MyApp',
            packageName: 'com.google.MyApp',
            version: '0.1.0',
            buildNumber: '1'));
    await upgrader.initialize();

    var called = false;
    var notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    final laterButton = find.text(upgrader.messages.buttonTitleLater);
    expect(laterButton, findsNothing);

    expect(called, false);
    expect(notCalled, true);
  });

  test('test upgrader shouldDisplayUpgrade', () async {
    final client = MockClient.setupMockClient();
    final upgrader = Upgrader();
    upgrader.client = client;
    upgrader.debugLogging = true;

    expect(upgrader.shouldDisplayUpgrade(), false);
    upgrader.debugDisplayAlways = true;
    expect(upgrader.shouldDisplayUpgrade(), true);
    upgrader.debugDisplayAlways = false;
    expect(upgrader.shouldDisplayUpgrade(), false);
  });
}

class _MyWidget extends StatelessWidget {
  const _MyWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Upgrader test'),
        ),
        body: UpgradeAlert(
            debugLogging: true,
            child: Column(
              children: <Widget>[Text('Upgrading')],
            )),
      ),
    );
  }
}

class _MyWidgetCard extends StatelessWidget {
  const _MyWidgetCard({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Upgrader test'),
        ),
        body: Column(
          children: <Widget>[UpgradeCard(debugLogging: true)],
        ),
      ),
    );
  }
}

class MyUpgraderMessages extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'aaa';
  @override
  String get buttonTitleLater => 'bbb';
  @override
  String get buttonTitleUpdate => 'ccc';
}
