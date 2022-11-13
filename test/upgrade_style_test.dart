import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_play_store_client.dart';
import 'widgets.dart';

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

  testWidgets('test upgrader with text styles applied in Android',
      (WidgetTester tester) async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final upgrader = Upgrader(
      platform: TargetPlatform.android,
      client: client,
      minAppVersion: '2.0.0',
      debugLogging: true,
      textStyles: UpgradeTextStyles(
        title: TextStyle(backgroundColor: Colors.amber),
        message: TextStyle(fontSize: 16),
        prompt: TextStyle(fontFamily: "Roboto"),
        titleReleaseNotes: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        bodyReleaseNotes: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    upgrader.installPackageInfo(
        packageInfo: PackageInfo(
            appName: 'Upgrader',
            packageName: 'com.testing.test2',
            version: '1.9.8',
            buildNumber: '42'));

    await upgrader.initialize();

    expect(upgrader.isUpdateAvailable(), true);

    expect(upgrader.isTooSoon(), false);

    await tester.pumpWidget(MyWidgetTest(upgrader: upgrader));

    expect(find.text('Upgrader test'), findsOneWidget);
    expect(find.text('Upgrading'), findsOneWidget);

// Pump the UI so the upgrader can display its dialog
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(upgrader.isTooSoon(), true);

    final titleStyle = _findTextStyleByText(
      tester,
      upgrader.messages.title,
    );

    expect(titleStyle, isNotNull);
    expect(titleStyle!.backgroundColor, Colors.amber);

    final messageStyle = _findTextStyleByText(
      tester,
      upgrader.message(),
    );

    expect(messageStyle, isNotNull);
    expect(messageStyle!.fontSize, 16);

    final promptStyle = _findTextStyleByText(
      tester,
      upgrader.messages.prompt,
    );

    expect(promptStyle, isNotNull);
    expect(promptStyle!.fontFamily, "Roboto");

    final titleReleaseStyle = _findTextStyleByText(
      tester,
      upgrader.messages.releaseNotes,
    );

    expect(titleReleaseStyle, isNotNull);
    expect(titleReleaseStyle!.fontSize, 18);
    expect(titleReleaseStyle.fontWeight, FontWeight.w900);

    final bodyReleaseStyle = _findTextStyleByText(
      tester,
      upgrader.releaseNotes!,
    );

    expect(bodyReleaseStyle, isNotNull);
    expect(bodyReleaseStyle!.color, Colors.black);
    expect(bodyReleaseStyle.fontWeight, FontWeight.w700);

    // Test variables
    expect(upgrader.textStyles.title, isNotNull);
    expect(upgrader.textStyles.message, isNotNull);
    expect(upgrader.textStyles.titleReleaseNotes, isNotNull);
    expect(upgrader.textStyles.bodyReleaseNotes, isNotNull);
    expect(upgrader.textStyles.prompt, isNotNull);

    expect(upgrader.textStyles.title!.backgroundColor, Colors.amber);
    expect(upgrader.textStyles.message!.fontSize, 16);

    expect(upgrader.textStyles.titleReleaseNotes!.fontSize, 18);
    expect(upgrader.textStyles.titleReleaseNotes!.fontWeight, FontWeight.w900);

    expect(upgrader.textStyles.bodyReleaseNotes!.color, Colors.black);
    expect(upgrader.textStyles.bodyReleaseNotes!.fontWeight, FontWeight.w700);

    expect(upgrader.textStyles.prompt!.fontFamily, "Roboto");
  }, skip: false);

  testWidgets('test upgrader with text styles applied in IOS',
      (WidgetTester tester) async {
    final upgrader = Upgrader(
      dialogStyle: UpgradeDialogStyle.cupertino,
      textStyles: UpgradeTextStyles(
        title: TextStyle(backgroundColor: Colors.amber),
        message: TextStyle(fontSize: 16),
        prompt: TextStyle(fontFamily: "Roboto"),
        titleReleaseNotes: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        bodyReleaseNotes: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    expect(upgrader.textStyles.title, isNotNull);
    expect(upgrader.textStyles.message, isNotNull);
    expect(upgrader.textStyles.titleReleaseNotes, isNotNull);
    expect(upgrader.textStyles.bodyReleaseNotes, isNotNull);
    expect(upgrader.textStyles.prompt, isNotNull);

    expect(upgrader.textStyles.title!.backgroundColor, Colors.amber);
    expect(upgrader.textStyles.message!.fontSize, 16);

    expect(upgrader.textStyles.titleReleaseNotes!.fontSize, 18);
    expect(upgrader.textStyles.titleReleaseNotes!.fontWeight, FontWeight.w900);

    expect(upgrader.textStyles.bodyReleaseNotes!.color, Colors.black);
    expect(upgrader.textStyles.bodyReleaseNotes!.fontWeight, FontWeight.w700);

    expect(upgrader.textStyles.prompt!.fontFamily, "Roboto");
  }, skip: false);
}

TextStyle? _findTextStyleByText(
  WidgetTester tester,
  String text,
) {
  return (tester.firstWidget(
    find.text(text),
  ) as Text)
      .style;
}
