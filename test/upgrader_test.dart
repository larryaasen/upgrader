/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'fake_appcast.dart';
import 'mock_itunes_client.dart';
import 'mock_play_store_client.dart';

// TODO: Need an integration test that runs on Android and iOS.

// Platform.operatingSystem can be "macos" or "linux" in a unit test.
// defaultTargetPlatform is TargetPlatform.android in a unit test.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await preferences.clear();
    return true;
  });

  testWidgets('test Upgrader sharedInstance', (WidgetTester tester) async {
    final upgrader1 = Upgrader.sharedInstance;
    expect(upgrader1, isNotNull);
    final upgrader2 = Upgrader.sharedInstance;
    expect(upgrader2, isNotNull);
    expect(upgrader1 == upgrader2, isTrue);
  }, skip: false);

  testWidgets('test Upgrader clearSavedSettings', (WidgetTester tester) async {
    await Upgrader.clearSavedSettings();
  }, skip: false);

  testWidgets('test Upgrader class', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // test code here
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader = Upgrader(
          platform: TargetPlatform.iOS, client: client, debugLogging: true);

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
  }, skip: false);

  testWidgets('test installAppStoreListingURL', (WidgetTester tester) async {
    final upgrader = Upgrader();
    upgrader.installAppStoreListingURL(
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');

    expect(upgrader.currentAppStoreListingURL(),
        'https://itunes.apple.com/us/app/google-maps-transit-food/id585027354?mt=8&uo=4');
  }, skip: false);

  testWidgets('test UpgradeWidget', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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
    expect(upgrader.messages.releaseNotes, 'Release Notes');

    upgrader.messages = MyUpgraderMessages();

    expect(upgrader.messages.buttonTitleIgnore, 'aaa');
    expect(upgrader.messages.buttonTitleLater, 'bbb');
    expect(upgrader.messages.buttonTitleUpdate, 'ccc');
    expect(upgrader.messages.releaseNotes, 'ddd');

    // await tester.runAsync(() async {
    final GlobalKey globalKey = GlobalKey();
    final myWidget = _MyWidget(key: globalKey, upgrader: upgrader);
    await tester.pumpWidget(myWidget);

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.messages.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader.messages.prompt), findsOneWidget);
    expect(find.byType(TextButton), findsNWidgets(3));
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleLater), findsOneWidget);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);

    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
    expect(find.text(upgrader.messages.releaseNotes), findsNothing);
    expect(called, true);
    expect(notCalled, true);
    // });
  }, skip: false);

  testWidgets('test UpgradeWidget Cupertino', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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
    upgrader.dialogStyle = UpgradeDialogStyle.cupertino;

    await tester.pumpWidget(_MyWidget(upgrader: upgrader));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    expect(find.text(upgrader.messages.title), findsOneWidget);
    expect(find.text(upgrader.message()), findsOneWidget);
    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    expect(find.text(upgrader.messages.prompt), findsOneWidget);
    expect(find.byType(CupertinoDialogAction), findsNWidgets(3));
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
  }, skip: false);

  testWidgets('test UpgradeWidget ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidget(upgrader: upgrader));

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidget(upgrader: upgrader));

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(called, true);
    expect(notCalled, true);
  }, skip: false);

  testWidgets('test UpgradeWidget pop scope', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(platform: TargetPlatform.iOS, client: client);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    var called = false;
    upgrader.shouldPopScope = () {
      called = true;
      return true;
    };

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(_MyWidget(upgrader: upgrader));

    // Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    // TODO: this test does not pop scope because there is no way to do that.
    // await tester.pageBack();
    // await tester.pumpAndSettle();
    // expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(called, false);
  }, skip: false);

  testWidgets('test UpgradeWidget Card upgrade', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidgetCard(upgrader: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    expect(find.text(upgrader.messages.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    await tester.tap(find.text(upgrader.messages.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidgetCard(upgrader: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.messages.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeWidget Card later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidgetCard(upgrader: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    await tester.tap(find.text(upgrader.messages.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
  }, skip: false);

  testWidgets('test upgrader minAppVersion', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);
    upgrader.minAppVersion = '1.0.0';

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), false);
    upgrader.minAppVersion = '0.5.0';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0';
    expect(upgrader.belowMinAppVersion(), true);
    upgrader.minAppVersion = null;
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = 'empty';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '0.9.9+4';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '0.9.9-5.2.pre';
    expect(upgrader.belowMinAppVersion(), false);
    upgrader.minAppVersion = '1.0.0-5.2.pre';
    expect(upgrader.belowMinAppVersion(), true);

    upgrader.minAppVersion = '1.0.0';

    await tester.pumpWidget(_MyWidgetCard(upgrader: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(find.text(upgrader.messages.buttonTitleIgnore), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleLater), findsNothing);
    expect(find.text(upgrader.messages.buttonTitleUpdate), findsOneWidget);
  }, skip: false);

  testWidgets('test upgrader minAppVersion description android',
      (WidgetTester tester) async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.android, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.testing.test2',
            version: '2.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.belowMinAppVersion(), true);
    expect(upgrader.minAppVersion, '4.5.6');
  }, skip: false);

  testWidgets('test upgrader minAppVersion description ios',
      (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient(
      description: 'Use this app. [:mav: 4.5.6]',
    );
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS, client: client, debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '2.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.belowMinAppVersion(), true);
    expect(upgrader.minAppVersion, '4.5.6');
  }, skip: false);

  testWidgets('test UpgradeWidget unknown app', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        platform: TargetPlatform.iOS,
        client: client,
        debugLogging: true,
        countryCode: 'IT',
        languageCode: 'en');

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'MyApp',
            packageName: 'com.google.MyApp',
            version: '0.1.0',
            buildNumber: '1'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(_MyWidgetCard(upgrader: upgrader));

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    final laterButton = find.text(upgrader.messages.buttonTitleLater);
    expect(laterButton, findsNothing);

    expect(called, false);
    expect(notCalled, true);
  }, skip: false);

  group('initialize', () {
    test('should use fake Appcast', () async {
      final fakeAppcast = FakeAppcast();
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader = Upgrader(
          platform: TargetPlatform.iOS,
          client: client,
          debugLogging: true,
          appcastConfig: fakeAppcast.config,
          appcast: fakeAppcast)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.6',
            buildNumber: '42',
          ),
        );

      await upgrader.initialize();

      expect(fakeAppcast.callCount, greaterThan(0));
    }, skip: false);

    test('durationUntilAlertAgain defaults to 3 days', () async {
      final upgrader = Upgrader();
      expect(upgrader.durationUntilAlertAgain, const Duration(days: 3));
    }, skip: false);

    test('durationUntilAlertAgain is 0 days', () async {
      final upgrader =
          Upgrader(durationUntilAlertAgain: const Duration(seconds: 0));
      expect(upgrader.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeAlert(upgrader: upgrader);
      expect(upgrader.durationUntilAlertAgain, const Duration(seconds: 0));

      UpgradeCard(upgrader: upgrader);
      expect(upgrader.durationUntilAlertAgain, const Duration(seconds: 0));
    }, skip: false);

    test('durationUntilAlertAgain card is valid', () async {
      final upgrader =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3));
      UpgradeCard(upgrader: upgrader);
      expect(upgrader.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10));
      UpgradeCard(upgrader: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);

    test('durationUntilAlertAgain alert is valid', () async {
      final upgrader =
          Upgrader(durationUntilAlertAgain: const Duration(days: 3));
      UpgradeAlert(upgrader: upgrader);
      expect(upgrader.durationUntilAlertAgain, const Duration(days: 3));

      final upgrader2 =
          Upgrader(durationUntilAlertAgain: const Duration(days: 10));
      UpgradeAlert(upgrader: upgrader2);
      expect(upgrader2.durationUntilAlertAgain, const Duration(days: 10));
    }, skip: false);
  });

  group('shouldDisplayUpgrade', () {
    test('should respect debugDisplayAlways property', () {
      final client = MockITunesSearchClient.setupMockClient();
      final upgrader = Upgrader(
          platform: TargetPlatform.iOS, client: client, debugLogging: true);

      expect(upgrader.shouldDisplayUpgrade(), false);
      upgrader.debugDisplayAlways = true;
      expect(upgrader.shouldDisplayUpgrade(), true);
      upgrader.debugDisplayAlways = false;
      expect(upgrader.shouldDisplayUpgrade(), false);

      // Test the willDisplayUpgrade callback
      var notCalled = true;
      upgrader.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, false);
        expect(minAppVersion, isNull);
        expect(installedVersion, isNull);
        expect(appStoreVersion, isNull);
        notCalled = false;
      };
      expect(upgrader.shouldDisplayUpgrade(), false);
      expect(notCalled, false);

      upgrader.debugDisplayAlways = true;
      notCalled = true;
      upgrader.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, true);
        expect(minAppVersion, isNull);
        expect(installedVersion, isNull);
        expect(appStoreVersion, isNull);
        notCalled = false;
      };
      expect(upgrader.shouldDisplayUpgrade(), true);
      expect(notCalled, false);
    }, skip: false);

    test('should return true when version is below minAppVersion', () async {
      final upgrader = Upgrader(
          debugLogging: true,
          platform: TargetPlatform.iOS,
          client: MockITunesSearchClient.setupMockClient())
        ..minAppVersion = '2.0.0'
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '1.9.6',
            buildNumber: '42',
          ),
        );

      await upgrader.initialize();
      var notCalled = true;
      upgrader.willDisplayUpgrade = (
          {required bool display,
          String? minAppVersion,
          String? installedVersion,
          String? appStoreVersion}) {
        expect(display, true);
        expect(minAppVersion, '2.0.0');
        expect(upgrader.minAppVersion, '2.0.0');
        expect(installedVersion, '1.9.6');
        expect(appStoreVersion, '5.6');
        notCalled = false;
      };

      final shouldDisplayUpgrade = upgrader.shouldDisplayUpgrade();

      expect(shouldDisplayUpgrade, isTrue);
      expect(notCalled, false);
    }, skip: false);

    test('should return true when bestItem has critical update', () async {
      final upgrader = Upgrader(
          debugLogging: true,
          platform: TargetPlatform.iOS,
          client: MockITunesSearchClient.setupMockClient())
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '2.0.0',
            buildNumber: '42',
          ),
        );

      await upgrader.initialize();

      final shouldDisplayUpgrade = upgrader.shouldDisplayUpgrade();

      expect(shouldDisplayUpgrade, isTrue);
    }, skip: false);

    test('packageInfo is empty', () async {
      final upgrader = Upgrader(
          client: MockITunesSearchClient.setupMockClient(),
          platform: TargetPlatform.iOS,
          debugLogging: true)
        ..installPackageInfo(
          packageInfo: PackageInfo(
            appName: '',
            packageName: '',
            version: '',
            buildNumber: '',
          ),
        );

      await upgrader.initialize();
      expect(upgrader.shouldDisplayUpgrade(), isFalse);
      expect(upgrader.appName(), isEmpty);
      expect(upgrader.currentInstalledVersion(), isEmpty);
    }, skip: false);
  });

  test('test UpgraderMessages', () {
    verifyMessages(UpgraderMessages(code: 'en'), 'en');
    verifyMessages(UpgraderMessages(code: 'ar'), 'ar');
    verifyMessages(UpgraderMessages(code: 'bn'), 'bn');
    verifyMessages(UpgraderMessages(code: 'da'), 'da');
    verifyMessages(UpgraderMessages(code: 'es'), 'es');
    verifyMessages(UpgraderMessages(code: 'fa'), 'fa');
    verifyMessages(UpgraderMessages(code: 'fil'), 'fil');
    verifyMessages(UpgraderMessages(code: 'fr'), 'fr');
    verifyMessages(UpgraderMessages(code: 'de'), 'de');
    verifyMessages(UpgraderMessages(code: 'el'), 'el');
    verifyMessages(UpgraderMessages(code: 'he'), 'he');
    verifyMessages(UpgraderMessages(code: 'hi'), 'hi');
    verifyMessages(UpgraderMessages(code: 'ht'), 'ht');
    verifyMessages(UpgraderMessages(code: 'hu'), 'hu');
    verifyMessages(UpgraderMessages(code: 'id'), 'id');
    verifyMessages(UpgraderMessages(code: 'it'), 'it');
    verifyMessages(UpgraderMessages(code: 'ja'), 'ja');
    verifyMessages(UpgraderMessages(code: 'kk'), 'kk');
    verifyMessages(UpgraderMessages(code: 'km'), 'km');
    verifyMessages(UpgraderMessages(code: 'ko'), 'ko');
    verifyMessages(UpgraderMessages(code: 'lt'), 'lt');
    verifyMessages(UpgraderMessages(code: 'mn'), 'mn');
    verifyMessages(UpgraderMessages(code: 'nb'), 'nb');
    verifyMessages(UpgraderMessages(code: 'nl'), 'nl');
    verifyMessages(UpgraderMessages(code: 'pt'), 'pt');
    verifyMessages(UpgraderMessages(code: 'pl'), 'pl');
    verifyMessages(UpgraderMessages(code: 'ru'), 'ru');
    verifyMessages(UpgraderMessages(code: 'sv'), 'sv');
    verifyMessages(UpgraderMessages(code: 'ta'), 'ta');
    verifyMessages(UpgraderMessages(code: 'te'), 'te');
    verifyMessages(UpgraderMessages(code: 'tr'), 'tr');
    verifyMessages(UpgraderMessages(code: 'uk'), 'uk');
    verifyMessages(UpgraderMessages(code: 'vi'), 'vi');
    verifyMessages(UpgraderMessages(code: 'zh'), 'zh');
  }, skip: false);
}

void verifyMessages(UpgraderMessages messages, String code) {
  expect(messages.languageCode, code);
  expect(messages.message(UpgraderMessage.body), isNotEmpty);
  expect(messages.message(UpgraderMessage.buttonTitleIgnore), isNotEmpty);
  expect(messages.message(UpgraderMessage.buttonTitleLater), isNotEmpty);
  expect(messages.message(UpgraderMessage.buttonTitleUpdate), isNotEmpty);
  expect(messages.message(UpgraderMessage.prompt), isNotEmpty);
  expect(messages.message(UpgraderMessage.releaseNotes), isNotEmpty);
  expect(messages.message(UpgraderMessage.title), isNotEmpty);
}

class _MyWidget extends StatelessWidget {
  final Upgrader upgrader;
  const _MyWidget({Key? key, required this.upgrader}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: UpgradeAlert(
            upgrader: upgrader,
            child: Column(
              children: const <Widget>[Text('Upgrading')],
            )),
      ),
    );
  }
}

class _MyWidgetCard extends StatelessWidget {
  final Upgrader upgrader;
  const _MyWidgetCard({Key? key, required this.upgrader}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: Column(
          children: <Widget>[UpgradeCard(upgrader: upgrader)],
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
  @override
  String get releaseNotes => 'ddd';
}
