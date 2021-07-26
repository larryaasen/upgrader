/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockPlayStoreSearchClient {
  static http.Client setupMockClient() {
    var id = 'com.kotoko.express';

    final client = MockClient((http.Request request) async {
      final response =
          '{"results": [{"version": "2.1.6", "id": "com.kotoko.express",  "releaseNotes": "Bug fixes and performance enhancements"}]}';

      final url = request.url.toString();

      // ignore: unrelated_type_equality_checks
      if (url == PlayStroeSearchAPI().lookupById(id)) {
        return http.Response(response, 200);
      }

      return http.Response('', 400);
    });

    return client;
  }
}
