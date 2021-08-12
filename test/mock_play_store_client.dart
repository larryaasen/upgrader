/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockPlayStoreSearchClient {
  static Future<http.Client> setupMockClient() async {
    var id = 'com.kotoko.express';

    final testPage = await getTestPage();
    final contents = await testPage.readAsString();

    final client = MockClient((http.Request request) async {
      final url = request.url.toString();
      if (url == PlayStoreSearchAPI().lookupURLById(id)) {
        return http.Response(contents, 200, headers: {
          HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
        });
      }

      return http.Response('', 404);
    });

    return client;
  }

  static Future<File> getTestPage() async {
    var testFile = File('test/test_play_store_page.txt');
    final exists = await testFile.exists();
    if (!exists) {
      testFile = File('test_play_store_page.txt');
    }
    return testFile;
  }
}
