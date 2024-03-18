/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:upgrader/src/appcast.dart';
import 'package:upgrader/src/upgrade_device.dart';

import 'appcast_test.dart';

class FakeAppcast extends Fake implements TestAppcast {
  FakeAppcast();
  int callCount = 0;

  @override
  AppcastItem bestItem() {
    callCount++;

    return AppcastItem(
      versionString: '1.0.0',
      fileURL: 'http://some.fakewebsite.com',
      tags: [],
    );
  }

  @override
  AppcastItem? bestCriticalItem() {
    callCount++;

    return AppcastItem(
      versionString: '1.0.0',
      fileURL: 'http://some.fakewebsite.com',
      tags: [],
    );
  }

  @override
  Future<List<AppcastItem>> parseAppcastItemsFromFile(File file) async {
    callCount++;

    return [AppcastItem()];
  }

  @override
  Future<List<AppcastItem>> parseAppcastItemsFromUri(String appCastURL) async {
    callCount++;

    return [AppcastItem()];
  }

  @override
  List<AppcastItem> parseItemsFromXMLString(String xmlString) {
    callCount++;

    return [AppcastItem()];
  }

  @override
  UpgraderDevice get upgraderDevice => MockUpgraderDevice();

  // AppcastConfiguration config =
  //     AppcastConfiguration(url: 'http://some.fakewebsite.com', supportedOS: [
  //   'android',
  //   'fuchsia',
  //   'ios',
  //   'linux',
  //   'macos',
  //   'web',
  //   'windows',
  // ]);

  @override
  List<AppcastItem>? items = [];

  @override
  String? osVersionString = '';
}
