/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info/package_info.dart';
import 'package:upgrader/upgrader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences preferences;

  const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/shared_preferences',
  );

  const Map<String, dynamic> kTestValues = <String, dynamic>{};

  setUp(() async {
    // This idea to mock the shared preferences taken from:
    /// https://github.com/flutter/plugins/blob/master/packages/shared_preferences/test/shared_preferences_test.dart
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return kTestValues;
      }
      return null;
    });
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await preferences.clear();
    await Upgrader().clearSavedSettings();
  });

  test('testing ITunesSearchAPI properties', () async {
    final iTunes = ITunesSearchAPI();
    expect(iTunes.debugEnabled, equals(false));
    iTunes.debugEnabled = true;
    expect(iTunes.debugEnabled, equals(true));
    expect(iTunes.iTunesDocumentationURL.length, greaterThan(0));
    expect(iTunes.lookupPrefixURL.length, greaterThan(0));
    expect(iTunes.searchPrefixURL.length, greaterThan(0));

    expect(iTunes.lookupURLByBundleId('com.google.Maps'),
        equals('https://itunes.apple.com/lookup?bundleId=com.google.Maps'));
    expect(iTunes.lookupURLById('585027354'),
        equals('https://itunes.apple.com/lookup?id=585027354'));
    expect(iTunes.lookupURLByQSP({'id': '909253', 'entity': 'album'}),
        equals('https://itunes.apple.com/lookup?id=909253&entity=album'));
  });

  test('testing lookupByBundleId', () async {
    final client = setupMockClient();
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupByBundleId('com.google.Maps');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 1);
    final result0 = results[0];
    expect(result0, isNotNull);
    expect(result0['bundleId'], 'com.google.Maps');
    expect(result0['version'], '5.6');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
  });

  test('testing lookupById', () async {
    final client = setupMockClient();
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupById('585027354');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 1);
    final result0 = results[0];
    expect(result0, isNotNull);
    expect(result0['bundleId'], 'com.google.Maps');
    expect(result0['version'], '5.6');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
  });

  testWidgets('test Upgrader class', (WidgetTester tester) async {
    final client = setupMockClient();
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
    final client = setupMockClient();
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
    final client = setupMockClient();
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
    final client = setupMockClient();
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

  testWidgets('test UpgradeWidget Card later', (WidgetTester tester) async {
    final client = setupMockClient();
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

    await tester.pumpWidget(_MyWidgetCard());

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    await tester.tap(find.text(upgrader.buttonTitleLater));
    await tester.pumpAndSettle();
    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.buttonTitleLater), findsNothing);
  });
}

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockClient extends Mock implements http.Client {}

http.Client setupMockClient() {
  final client = MockClient();

  // Use Mockito to return a successful response when it calls the
  // provided http.Client
  final r = '{"results": [{"version": "5.6", "bundleId": "com.google.Maps"}]}';
  when(client.get(ITunesSearchAPI().lookupURLById('585027354')))
      .thenAnswer((_) async => http.Response(r, 200));
  when(client.get(ITunesSearchAPI().lookupURLByBundleId('com.google.Maps')))
      .thenAnswer((_) async => http.Response(r, 200));
  when(client.get(
          ITunesSearchAPI().lookupURLByBundleId('com.larryaasen.upgrader')))
      .thenAnswer((_) async => http.Response(r, 200));

  return client;
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
