import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_play_store_client.dart';

void main() {
  testWidgets('test upgrader with text styles applied in Android',
      (WidgetTester tester) async {
    final upgrader = Upgrader(
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
