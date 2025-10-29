/*
 * Test for version parsing issue #521
 * https://github.com/larryaasen/upgrader/issues/521
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('testing Play Store version parsing issue #521', () async {
    // Load the actual Play Store HTML that causes the issue
    final testFile = File('test/test_play_store_page_issue521.txt');
    final exists = testFile.existsSync();

    if (!exists) {
      print('Test file not found: test/test_play_store_page_issue521.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    // Try to parse version from regional Play Store page (Korean example)
    final version = playStore.version(document);

    print('Parsed version: $version');

    // FIXED: Issue #521 has been fixed! Now it successfully parses regional pages
    // Using alternative pattern "141":[[["1.5.1" for regional Play Store pages
    expect(version, equals('1.5.1'),
        reason:
            'FIXED #521: Version parsing now works for regional Play Store pages using alternative pattern');
  }, skip: false);

  test('testing redesignedVersion for issue #521', () async {
    final testFile = File('test/test_play_store_page_issue521.txt');
    final exists = testFile.existsSync();

    if (!exists) {
      print('Test file not found: test/test_play_store_page_issue521.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    // Directly test the redesignedVersion method
    final version = playStore.redesignedVersion(document);

    print('Redesigned version: $version');

    // FIXED: Now successfully parses regional pages using alternative pattern
    // Falls back to "141":[[["1.5.1" pattern when main pattern fails
    expect(version, equals('1.5.1'),
        reason:
            'FIXED #521: redesignedVersion now handles regional Play Store pages correctly');
  }, skip: false);

  test('FormatException issue #521 is now fixed', () async {
    // This test verifies that issue #521 has been fixed:
    // The original error was "PlayStoreResults.redesignedVersion exception: FormatException: Not a properly formatted version string"
    // Now it should successfully parse the version using alternative pattern

    final testFile = File('test/test_play_store_page_issue521.txt');
    if (!testFile.existsSync()) {
      print('Test file not found: test/test_play_store_page_issue521.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    // Now it should successfully parse the version without throwing an exception
    final version = playStore.version(document);

    // FIXED: Now returns the actual version instead of null
    expect(version, equals('1.5.1'),
        reason:
            'FIXED #521: Version parsing now works correctly for regional Play Store pages');
  }, skip: false);
}
