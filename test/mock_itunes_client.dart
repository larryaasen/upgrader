/*
 * Copyright (c) 2019-2021 Larry Aasen. All rights reserved.
 */

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockITunesSearchClient {
  static http.Client setupMockClient({String country = 'US'}) {
    final currency = country == 'US'
        ? 'USD'
        : country == 'FR'
            ? 'EUR'
            : '';

    final client = MockClient((http.Request request) async {
      final response =
          '{"results": [{"version": "5.6", "bundleId": "com.google.Maps", "currency": "$currency", "releaseNotes": "Bug fixes."}]}';

      final url = request.url.toString();
      if (url ==
          ITunesSearchAPI().lookupURLById('585027354', country: country)) {
        return http.Response(response, 200);
      }
      if (url ==
          ITunesSearchAPI()
              .lookupURLByBundleId('com.google.Maps', country: country)) {
        return http.Response(response, 200);
      }
      if (url ==
          ITunesSearchAPI().lookupURLByBundleId('com.larryaasen.upgrader',
              country: country)) {
        return http.Response(response, 200);
      }
      if (url ==
          ITunesSearchAPI()
              .lookupURLByBundleId('com.google.MyApp', country: country)) {
        final responseMyApp = '{"resultCount": 0,"results": []}';
        return http.Response(responseMyApp, 200);
      }
      return http.Response('', 400);
    });

    return client;
  }
}
