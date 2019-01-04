/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  setUp(() async {});

  tearDown(() async {});

  /// These tests inspired by:
  ///   https://github.com/sparkle-project/Sparkle/blob/master/Tests/SUAppcastTest.swift
  test('testing Appcast', () async {
    // Flutter testings assumes the platform is android, so verify it.
    expect(defaultTargetPlatform, equals(TargetPlatform.android));

    final appcast = Appcast();
    expect(appcast.bestItem(), isNull);
    expect(appcast.osVersionString, isNull);
    expect(appcast.items, isNull);
    expect(appcast.parseItemsFromXMLString('asdlfkjasdflkj'), isNull);
    expect(appcast.parseItemsFromXMLString('</channel>'), isNull);
    expect(await appcast.parseAppcastItemsFromUri('asdfasdf'), isNull);
  });

  test('testing Appcast file', () async {
    // Flutter testings assumes the platform is android, so verify it.
    expect(defaultTargetPlatform, equals(TargetPlatform.android));

    final appcast = Appcast();
    File testFile = await getTestFile();
    final items = await appcast.parseAppcastItemsFromFile(testFile);
    validateItems(items, appcast);
  });

  test('testing Appcast ', () async {
    final client = await setupMockClient();
    final appcast = Appcast(client: client);
    final items = await appcast.parseAppcastItemsFromUri(
        'https://sparkle-project.org/test/testappcast.xml');
    validateItems(items, appcast);
  });
}

void validateItems(List<AppcastItem> items, Appcast appcast) {
  expect(items.length, equals(4));

  appcast.osVersionString = '0.0.1';

  expect(items[0].title, equals('Version 2.0'));
  expect(items[0].itemDescription, equals('desc'));
  expect(items[0].dateString, equals('Sat, 26 Jul 2014 15:20:11 +0000'));
  expect(
      items[0].fileURL, equals('http://localhost:1337/Sparkle_Test_App.zip'));
  expect(items[0].isCriticalUpdate, equals(true));
  expect(items[0].maximumSystemVersion, isNull);
  expect(items[0].minimumSystemVersion, isNull);
  expect(items[0].versionString, equals('2.0'));
  expect(items[0].hostSupportsItem(osVersion: '0.0.1'), equals(true));
  expect(items[0].osString, isNull);

  expect(items[1].title, equals('Version 3.0'));
  expect(items[1].itemDescription, equals(null));
  expect(items[1].dateString, equals(null));
  expect(
      items[1].fileURL, equals('http://localhost:1337/Sparkle_Test_App.zip'));
  expect(items[1].isCriticalUpdate, equals(false));
  expect(items[1].maximumSystemVersion, isNull);
  expect(items[1].minimumSystemVersion, isNull);
  expect(items[1].versionString, equals('3.0'));
  expect(items[1].hostSupportsItem(osVersion: '0.0.1'), equals(true));
  expect(items[1].osString, equals('android'));

  expect(items[2].title, equals('Version 4.0'));
  expect(items[2].itemDescription, equals(null));
  expect(items[2].dateString, "Sat, 26 Jul 2014 15:20:13 +0000");
  expect(
      items[2].fileURL, equals('http://localhost:1337/Sparkle_Test_App.zip'));
  expect(items[2].isCriticalUpdate, equals(false));
  expect(items[2].maximumSystemVersion, isNull);
  expect(items[2].minimumSystemVersion, equals('17.0.0'));
  expect(items[2].versionString, equals('4.0'));
  expect(items[2].hostSupportsItem(osVersion: '0.0.1'), equals(false));
  expect(items[2].hostSupportsItem(osVersion: '17.0.1', currentPlatform: 'iOS'),
      equals(true));
  expect(items[2].osString, equals('iOS'));

  expect(items[3].title, equals('Version 5.0'));
  expect(items[3].itemDescription, equals(null));
  expect(items[3].dateString, equals(null));
  expect(items[3].fileURL, isNull);
  expect(items[3].isCriticalUpdate, equals(false));
  expect(items[3].maximumSystemVersion, equals('2.0.0'));
  expect(items[3].minimumSystemVersion, isNull);
  expect(items[3].versionString, equals('5.0'));
  expect(items[3].hostSupportsItem(osVersion: '0.0.1'), equals(true));
  expect(items[3].hostSupportsItem(osVersion: '2.0.1'), equals(false));
  expect(items[3].osString, isNull);

  final bestItem = appcast.bestItem();
  expect(bestItem, isNotNull);
  expect(bestItem.versionString, equals('5.0'));
  expect(bestItem.hostSupportsItem(osVersion: '0.0.1'), equals(true));
  expect(bestItem.osString, isNull);
}

Future<File> getTestFile() async {
  File testFile = File('test/testappcast.xml');
  final exists = await testFile.exists();
  if (!exists) {
    testFile = File('testappcast.xml');
  }
  return testFile;
}

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockClient extends Mock implements http.Client {}

Future<http.Client> setupMockClient() async {
  final client = MockClient();

  // Use Mockito to return a successful response when it calls the
  // provided http.Client
  final testFile = await getTestFile();
  final contents = await testFile.readAsString();
  when(client.get('https://sparkle-project.org/test/testappcast.xml'))
      .thenAnswer((_) async => http.Response(contents, 200));

  return client;
}
