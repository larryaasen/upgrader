/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setMockDeviceInfo();

  setUp(() async {});

  tearDown(() async {});

  test('testing defaultTargetPlatform', () async {
    // Platform.operatingSystem can be "macos" or "linux" in a unit test.
    // defaultTargetPlatform is TargetPlatform.android in a unit test.

    // Flutter testings assumes the platform is android, so verify it.
    expect(defaultTargetPlatform, equals(TargetPlatform.android));
  });

  /// These tests inspired by:
  ///   https://github.com/sparkle-project/Sparkle/blob/master/Tests/SUAppcastTest.swift
  test('testing Appcast', () async {
    final appcast = Appcast();
    expect(appcast.bestItem(), isNull);
    expect(appcast.osVersionString, isNull);
    expect(appcast.items, isNull);
    expect(appcast.parseItemsFromXMLString('asdlfkjasdflkj'), isNull);
    expect(appcast.parseItemsFromXMLString('</channel>'), isNull);
    expect(await appcast.parseAppcastItemsFromUri('asdfasdf'), isNull);
  });

  test('testing Appcast file', () async {
    final appcast = TestAppcast();
    var testFile = await getTestFile();
    final items = await appcast.parseAppcastItemsFromFile(testFile);
    validateItems(items!, appcast);
  });

  test('testing Appcast ', () async {
    final client = await setupMockClient();
    final appcast = Appcast(client: client);
    final items = await appcast.parseAppcastItemsFromUri(
        'https://sparkle-project.org/test/testappcast.xml');
    validateItems(items!, appcast);
  }, skip: false);

  test(
      'testing Appcast will prioritize critical version even with lover version. ',
      () async {
    final appcast = TestAppcast();

    final testFile =
        await getTestFile(filePath: 'test/testappcast_critical.xml');

    await appcast.parseAppcastItemsFromFile(testFile);

    final bestCriticalItem = appcast.bestCriticalItem();

    expect(
      bestCriticalItem?.versionString == "3.0.0",
      equals(true),
    );

    expect(bestCriticalItem?.tags?.contains("sparkle:criticalUpdate"),
        equals(true));
  }, skip: false);

  test('testing Appcast host', () async {
    final item = AppcastItem();

    expect(item.hostSupportsItem(osVersion: null), equals(true));
    expect(item.hostSupportsItem(osVersion: ''), equals(true));
    expect(item.hostSupportsItem(osVersion: '0'), equals(true));

    expect(
        item.hostSupportsItem(
            osVersion:
                'samsung/hero2ltexx/hero2lte:7.0/NRD90M/G935FXXU2DRB6:user/release-keys'),
        equals(false));

    expect(item.hostSupportsItem(osVersion: '0.1'), equals(true));

    expect(item.hostSupportsItem(osVersion: '0.0.1'), equals(true));
  });
}

void validateItems(List<AppcastItem> items, Appcast appcast) {
  expect(items.length, equals(4));

  appcast.osVersionString = '0.0.1';

  expect(items[0].title, equals('Version 2.0'));
  expect(items[0].itemDescription, equals('desc Версия'));
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
  expect(items[2].dateString, 'Sat, 26 Jul 2014 15:20:13 +0000');
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

  final bestItem = appcast.bestItem()!;
  expect(bestItem, isNotNull);
  expect(bestItem.versionString, equals('5.0'));
  expect(bestItem.hostSupportsItem(osVersion: '0.0.1'), equals(true));
  expect(bestItem.osString, isNull);
}

Future<File> getTestFile({String filePath = 'test/testappcast.xml'}) async {
  var testFile = File(filePath);
  final exists = await testFile.exists();
  if (!exists) {
    testFile = File('testappcast.xml');
  }
  return testFile;
}

Future<http.Client> setupMockClient(
    {String filePath = 'test/testappcast.xml'}) async {
  // Use a mock to return a successful response when it calls the
  // provided http.Client.

  final client = MockClient((http.Request request) async {
    if (request.url.toString() ==
        'https://sparkle-project.org/test/testappcast.xml') {
      final testFile = await getTestFile(filePath: filePath);
      final contents = await testFile.readAsString();
      return http.Response.bytes(utf8.encode(contents), 200);
    }
    return http.Response('', 400);
  });

  return client;
}

class TestAppcast extends Appcast {
  /// Load the Appcast from [file].
  Future<List<AppcastItem>?> parseAppcastItemsFromFile(File file) async {
    final contents = await file.readAsString();
    return parseAppcastItems(contents);
  }
}

void setMockDeviceInfo() {
  const channel = MethodChannel('dev.fluttercommunity.plus/device_info');

  handler(MethodCall methodCall) async {
    print('setMockDeviceInfo.methodCall: ${methodCall.method}');

    switch (methodCall.method) {
      case 'getMacosDeviceInfo':
      case 'getDeviceInfo':
        return <String, dynamic>{
          'computerName': '',
          'hostName': '',
          'arch': '',
          'model': '',
          'kernelVersion': '',
          'osRelease': 'Version 13.2.1 (Build 22D68)',
          'majorVersion': 13,
          'minorVersion': 2,
          'patchVersion': 1,
          'activeCPUs': 0,
          'memorySize': 0,
          'cpuFrequency': 0,
          'systemGUID': '',
        };

      default:
        assert(false);
        return null;
    }
  }

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, handler);
}
