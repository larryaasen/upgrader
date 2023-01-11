/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

final _filenames = {
  'com.kotoko.express': 'test_play_store_page1.txt',
  'com.testing.test2': 'test_play_store_page2.txt',
  'com.testing.test3': 'test_play_store_page3.txt',
  'com.testing.test4': 'test_play_store_page4.txt',
  'com.testing.test5': 'test_play_store_page5.txt',
};

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockPlayStoreSearchClient {
  static Future<http.Client> setupMockClient() async {
    final client = MockClient((http.Request request) async {
      var url = request.url.toString();
      final index = url.indexOf('_cb=');
      if (index > 0) {
        url = url.substring(0, index - 1);
      }
      final id = request.url.queryParameters['id'];
      if (id != null) {
        final filename = _filenames[id];
        if (filename != null && filename.isNotEmpty) {
          if (url ==
              PlayStoreSearchAPI().lookupURLById(id, useCacheBuster: false)) {
            final testPage = await getTestPage(filename);
            final contents = testPage.readAsStringSync();
            return http.Response(contents, 200, headers: {
              HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
            });
          }
        }
      }

      return http.Response('', 404);
    });

    return client;
  }

  static Future<File> getTestPage(String filename) async {
    var testFile = File('test/$filename');
    final exists = testFile.existsSync();
    if (!exists) {
      testFile = File(filename);
    }
    return testFile;
  }
}
