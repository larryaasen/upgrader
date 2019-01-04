/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info/package_info.dart';
import 'package:upgrader/upgrader.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mockclient.dart';

void main() {
  SharedPreferences preferences;

  const MethodChannel sharedPrefsChannel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  const Map<String, dynamic> kEmptyPreferences = <String, dynamic>{};

  setUp(() async {
    // This idea to mock the shared preferences taken from:
    /// https://github.com/flutter/plugins/blob/master/packages/shared_preferences/test/shared_preferences_test.dart
    sharedPrefsChannel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return kEmptyPreferences;
      }
      return null;
    });
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await preferences.clear();
    await Upgrader().clearSavedSettings();
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

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    await upgrader.initialize();

    bool called = false;
    bool notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
    };
    upgrader.onLater = () {
      notCalled = false;
    };

    expect(upgrader.isUpdateAvailable(), true);
    expect(upgrader.isTooSoon(), false);

    expect(upgrader.buttonTitleIgnore, 'IGNORE');
    expect(upgrader.buttonTitleLater, 'LATER');
    expect(upgrader.buttonTitleUpdate, 'UPDATE NOW');

    upgrader.buttonTitleIgnore = 'aaa';
    upgrader.buttonTitleLater = 'bbb';
    upgrader.buttonTitleUpdate = 'ccc';

    expect(upgrader.buttonTitleIgnore, 'aaa');
    expect(upgrader.buttonTitleLater, 'bbb');
    expect(upgrader.buttonTitleUpdate, 'ccc');

    await tester.pumpWidget(_MyWidget());

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.prompt), findsOneWidget);
    expect(find.byType(FlatButton), findsNWidgets(3));
    expect(find.text(upgrader.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader.buttonTitleUpdate), findsOneWidget);

    await tester.tap(find.text(upgrader.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.buttonTitleUpdate), findsNothing);
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

    bool called = false;
    bool notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onUpdate = () {
      notCalled = false;
    };
    upgrader.onLater = () {
      notCalled = false;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget());

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleIgnore));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.buttonTitleIgnore), findsNothing);
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

    bool called = false;
    bool notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
    };
    upgrader.onUpdate = () {
      notCalled = false;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget());

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.buttonTitleLater), findsNothing);
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

    bool called = false;
    bool notCalled = true;
    upgrader.onUpdate = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
    };
    upgrader.onIgnore = () {
      notCalled = false;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.buttonTitleUpdate), findsNothing);
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

    bool called = false;
    bool notCalled = true;
    upgrader.onIgnore = () {
      called = true;
      return true;
    };
    upgrader.onLater = () {
      notCalled = false;
    };
    upgrader.onUpdate = () {
      notCalled = false;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.buttonTitleIgnore), findsNothing);
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

    bool called = false;
    bool notCalled = true;
    upgrader.onLater = () {
      called = true;
      return true;
    };
    upgrader.onIgnore = () {
      notCalled = false;
    };
    upgrader.onUpdate = () {
      notCalled = false;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.buttonTitleLater), findsNothing);
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
          children: <Widget>[UpgradeCard()],
        ),
      ),
    );
  }
}
