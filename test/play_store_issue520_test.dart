/*
 * Test for version parsing issue #520 with Egypt Play Store page
 * https://github.com/larryaasen/upgrader/issues/520
 *
 * Issue: The redesignedVersion method incorrectly extracts "Shopping"
 * instead of the actual version "1.0.11" from certain regional Play Store pages.
 *
 * The problem occurs because the pattern ",[[[\"" matches non-version data
 * (like category names "Shopping") before finding the actual version number.
 */

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('Egypt Play Store page version parsing should not extract "Shopping"',
      () async {
    // Load the Egypt Play Store HTML that causes the issue
    final testFile = File('test/test_play_store_page_issue520.txt');
    final exists = testFile.existsSync();

    if (!exists) {
      print('Test file not found: test/test_play_store_page_issue520.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    // Try to parse version from Egypt Play Store page
    final version = playStore.version(document);

    print('Parsed version: $version');

    // The actual version in the Play Store page is "1.0.11"
    // The bug currently extracts "Shopping" which fails Version.parse()
    // resulting in null
    expect(version, equals('1.0.11'),
        reason:
            'Should correctly parse version "1.0.11" from Egypt Play Store page, not extract "Shopping"');
  }, skip: false);

  test('redesignedVersion should handle Egypt Play Store page correctly',
      () async {
    final testFile = File('test/test_play_store_page_issue520.txt');
    final exists = testFile.existsSync();

    if (!exists) {
      print('Test file not found: test/test_play_store_page_issue520.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    // Directly test the redesignedVersion method
    final version = playStore.redesignedVersion(document);

    print('Redesigned version: $version');

    // Should extract the correct version, not "Shopping"
    expect(version, equals('1.0.11'),
        reason:
            'redesignedVersion should extract "1.0.11", not "Shopping" or other non-version strings');
  }, skip: false);

  test('version parsing should not return null for valid Egypt page', () async {
    final testFile = File('test/test_play_store_page_issue520.txt');
    if (!testFile.existsSync()) {
      print('Test file not found: test/test_play_store_page_issue520.txt');
      return;
    }

    final contents = testFile.readAsStringSync();
    final document = parse(contents);

    final playStore = PlayStoreSearchAPI();
    playStore.debugLogging = true;

    final version = playStore.version(document);

    // Version should not be null when a valid version exists in the page
    expect(version, isNotNull,
        reason:
            'Version should not be null for Egypt Play Store page with valid version data');

    // And it should be a valid version format
    expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')),
        reason: 'Version should match semantic version format X.Y.Z');
  }, skip: false);
}
