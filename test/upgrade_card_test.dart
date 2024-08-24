// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_itunes_client.dart';
import 'test_utils.dart';

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
  testWidgets('test UpgradeCard no update', (WidgetTester tester) async {
    expect(Upgrader.sharedInstance.isTooSoon(), false);

    final upgradeCard = wrapper(UpgradeCard());
    await tester.pumpWidget(upgradeCard);

    // Pump the UI
    await tester.pumpAndSettle();

    expect(find.text('IGNORE'), findsNothing);
    expect(find.text('LATER'), findsNothing);
    expect(find.text('UPDATE'), findsNothing);
    expect(find.text('Release Notes'), findsNothing);
  });

  testWidgets('test UpgradeCard upgrade', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), false);

    var called = false;
    var notCalled = true;
    final upgradeCard = wrapper(
      UpgradeCard(
        upgrader: upgrader,
        onUpdate: () {
          called = true;
          return true;
        },
        onIgnore: () {
          notCalled = false;
          return true;
        },
        onLater: () {
          notCalled = false;
        },
      ),
    );
    await tester.pumpWidget(upgradeCard);

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    expect(upgrader.state.messages, isNull);
    upgrader.updateState(upgrader.state.copyWith(messages: UpgraderMessages()));
    expect(upgrader.state.messages, isNotNull);

    expect(find.text(upgrader.state.messages!.releaseNotes), findsOneWidget);
    expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    await tester.tap(find.text(upgrader.state.messages!.buttonTitleUpdate));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.state.messages!.buttonTitleUpdate), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeCard ignore', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), false);

    var called = false;
    var notCalled = true;
    final upgradeCard = wrapper(
      UpgradeCard(
        upgrader: upgrader,
        onUpdate: () {
          notCalled = false;
          return true;
        },
        onIgnore: () {
          called = true;
          return true;
        },
        onLater: () {
          notCalled = false;
        },
      ),
    );
    await tester.pumpWidget(upgradeCard);

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle();

    expect(upgrader.state.messages, isNull);
    upgrader.updateState(upgrader.state.copyWith(messages: UpgraderMessages()));
    expect(upgrader.state.messages, isNotNull);

    await tester.tap(find.text(upgrader.state.messages!.buttonTitleIgnore));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.state.messages!.buttonTitleIgnore), findsNothing);
  }, skip: false);

  testWidgets('test UpgradeCard later', (WidgetTester tester) async {
    final client = MockITunesSearchClient.setupMockClient();
    final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true);

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.larryaasen.upgrader',
            version: '0.9.9',
            buildNumber: '400'));
    upgrader.initialize().then((value) {});
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), false);

    var called = false;
    var notCalled = true;
    final upgradeCard = wrapper(
      UpgradeCard(
        upgrader: upgrader,
        onUpdate: () {
          notCalled = false;
          return true;
        },
        onIgnore: () {
          notCalled = false;
          return true;
        },
        onLater: () {
          called = true;
        },
      ),
    );
    await tester.pumpWidget(upgradeCard);

    // Pump the UI so the upgrade card is displayed
    await tester.pumpAndSettle(const Duration(milliseconds: 5000));

    expect(upgrader.state.messages, isNull);
    upgrader.updateState(upgrader.state.copyWith(messages: UpgraderMessages()));
    expect(upgrader.state.messages, isNotNull);

    await tester.tap(find.text(upgrader.state.messages!.buttonTitleLater));
    await tester.pumpAndSettle();

    expect(called, true);
    expect(notCalled, true);
    expect(find.text(upgrader.state.messages!.buttonTitleLater), findsNothing);
  }, skip: false);
}
