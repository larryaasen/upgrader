// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_itunes_client.dart';

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

  group("UpgradeAnnouncer", () {
    testWidgets('Upgrade enforce; always shown; debugEnforceUpgrade',
        (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '5.6',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          debugEnforceUpgrade: true,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsNothing);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; always shown; debugAvailableUpgrade',
        (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '5.6',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          debugAvailableUpgrade: true,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);
    }, skip: false);

    testWidgets('No upgrade available', (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '5.6',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsNothing);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);
    }, skip: false);

    testWidgets('Upgrade available', (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);

      expect(
          find.byWidgetPredicate((widget) =>
              widget is MaterialBanner &&
              widget.backgroundColor == Colors.green),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == Icons.info_outline &&
              widget.color == Colors.white),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == Icons.download &&
              widget.color == Colors.white),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == UpgraderMessages().upgradeAvailable &&
              widget.style?.color == Colors.white),
          findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; bottomSheetBuilder',
        (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      const bottomSheetContainerColor = Colors.teal;
      const bottomSheetBuilderTextStyle =
          TextStyle(color: Colors.yellow, fontSize: 12);

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          bottomSheetBuilder: (context, goToAppStore, releaseNotes) =>
              Container(
            color: bottomSheetContainerColor,
            child: Text(
              releaseNotes!,
              style: bottomSheetBuilderTextStyle,
            ),
          ),
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);

      await tester.tap(find.text(UpgraderMessages().upgradeAvailable));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.color == bottomSheetContainerColor,
          ),
          findsOneWidget);
      expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text && widget.style == bottomSheetBuilderTextStyle,
          ),
          findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; icons, styles and colors',
        (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      const backgroundColor = Colors.red;
      const infoIcon = Icons.add;
      const infoIconColor = Colors.blue;
      const downloadIcon = Icons.abc;
      const downloadIconColor = Colors.yellow;
      const titleTextStyle = TextStyle(color: Colors.amber, fontSize: 20);
      const bottomSheetTitleTextStyle =
          TextStyle(color: Colors.orange, fontSize: 25);
      const bottomSheetReleaseNotesTextStyle =
          TextStyle(color: Colors.purple, fontSize: 30);
      const bottomSheetBackgroundColor = Colors.teal;

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          backgroundColor: backgroundColor,
          infoIcon: infoIcon,
          infoIconColor: infoIconColor,
          downloadIcon: downloadIcon,
          downloadIconColor: downloadIconColor,
          titleTextStyle: titleTextStyle,
          bottomSheetTitleTextStyle: bottomSheetTitleTextStyle,
          bottomSheetReleaseNotesTextStyle: bottomSheetReleaseNotesTextStyle,
          bottomSheetBackgroundColor: bottomSheetBackgroundColor,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);

      expect(
          find.byWidgetPredicate((widget) =>
              widget is MaterialBanner &&
              widget.backgroundColor == backgroundColor),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == infoIcon &&
              widget.color == infoIconColor),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == downloadIcon &&
              widget.color == downloadIconColor),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == UpgraderMessages().upgradeAvailable &&
              widget.style == titleTextStyle),
          findsOneWidget);

      await tester.tap(find.text(UpgraderMessages().upgradeAvailable));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == downloadIcon &&
              widget.color == downloadIconColor),
          findsNWidgets(2));
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == UpgraderMessages().newInThisVersion &&
              widget.style == bottomSheetTitleTextStyle),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == upgrader.releaseNotes &&
              widget.style == bottomSheetReleaseNotesTextStyle),
          findsOneWidget);
      expect(
          find.byWidgetPredicate(
            (themeData) =>
                themeData is BottomSheet &&
                themeData.backgroundColor == bottomSheetBackgroundColor,
          ),
          findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; release notes in bottom sheet',
        (WidgetTester tester) async {
      final client = MockITunesSearchClient.setupMockClient();

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);

      await tester.tap(find.text(UpgraderMessages().upgradeAvailable));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().newInThisVersion), findsOneWidget);
      expect(find.byIcon(Icons.download), findsNWidgets(2));
      expect(find.text(upgrader.releaseNotes!), findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; no enforce upgrade',
        (WidgetTester tester) async {
      final client =
          MockITunesSearchClient.setupMockClient(description: '[:mav: 5.7]');

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          enforceUpgrade: false,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);
      expect(find.text(UpgraderMessages().upgradeAvailable), findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; enforce upgrade',
        (WidgetTester tester) async {
      final client =
          MockITunesSearchClient.setupMockClient(description: '[:mav: 5.7]');

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          upgrader: upgrader,
          enforceUpgrade: true,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text(UpgraderMessages().upgradeEnforce), findsOneWidget);
      expect(find.text(UpgraderMessages().upgradeAvailable), findsNothing);
    }, skip: false);

    testWidgets('Upgrade available; enforce upgrade; enforceUpgradeBuilder',
        (WidgetTester tester) async {
      final client =
          MockITunesSearchClient.setupMockClient(description: '[:mav: 5.7]');

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      const enforceUpgradeBuilderContainerColor = Colors.teal;
      const enforceUpgradeBuilderText = 'Testing builder';
      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          enforceUpgradeBuilder: (context, _) => Container(
            color: enforceUpgradeBuilderContainerColor,
            child: const Text(enforceUpgradeBuilderText),
          ),
          enforceUpgrade: true,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeEnforce), findsNothing);

      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.color == enforceUpgradeBuilderContainerColor),
          findsOneWidget);
      expect(find.text(enforceUpgradeBuilderText), findsOneWidget);
    }, skip: false);

    testWidgets('Upgrade available; enforce upgrade; icons, styles and colors',
        (WidgetTester tester) async {
      final client =
          MockITunesSearchClient.setupMockClient(description: '[:mav: 5.7]');

      final upgrader = Upgrader(
        upgraderOS: MockUpgraderOS(ios: true),
        client: client,
        debugLogging: true,
      );

      upgrader.installPackageInfo(
          packageInfo: PackageInfo(
        appName: 'Upgrader',
        packageName: 'com.larryaasen.upgrader',
        version: '0.9.9',
        buildNumber: '400',
      ));

      final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
          GlobalKey<ScaffoldMessengerState>();

      const infoIcon = Icons.add;
      const infoIconColor = Colors.blue;
      const downloadIcon = Icons.abc;
      const downloadIconColor = Colors.yellow;
      const enforceUpgradeBackgroundColor = Colors.red;
      const enforceUpgradeTextStyle =
          TextStyle(color: Colors.amber, fontSize: 20);
      final testWidget = MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        home: UpgradeAnnouncer(
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          infoIcon: infoIcon,
          infoIconColor: infoIconColor,
          downloadIcon: downloadIcon,
          downloadIconColor: downloadIconColor,
          enforceUpgradeBackgroundColor: enforceUpgradeBackgroundColor,
          enforceUpgradeTextStyle: enforceUpgradeTextStyle,
          enforceUpgrade: true,
          upgrader: upgrader,
          child: Scaffold(
            body: const Placeholder(),
            appBar: AppBar(title: const Text('Upgrader test')),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text(UpgraderMessages().upgradeEnforce), findsOneWidget);

      expect(
          find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.decoration ==
                  BoxDecoration(
                      color: enforceUpgradeBackgroundColor,
                      borderRadius: BorderRadius.circular(16))),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == infoIcon &&
              widget.color == infoIconColor),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Icon &&
              widget.icon == downloadIcon &&
              widget.color == downloadIconColor),
          findsOneWidget);
      expect(
          find.byWidgetPredicate((widget) =>
              widget is Text &&
              widget.data == UpgraderMessages().upgradeEnforce &&
              widget.style == enforceUpgradeTextStyle),
          findsOneWidget);
    }, skip: false);
  });
}
