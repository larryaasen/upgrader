/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:upgrader/upgrader.dart';

// Create a MockClient using the Mock class provided by the Mockito package.
// We will create a new instances of this class in each test.
class MockClient extends Mock implements http.Client {
  static http.Client setupMockClient() {
    final client = MockClient();

    // Use Mockito to return a successful response when it calls the
    // provided http.Client
    final r =
        '{"results": [{"version": "5.6", "bundleId": "com.google.Maps"}]}';
    when(client.get(ITunesSearchAPI().lookupURLById('585027354')))
        .thenAnswer((_) async => http.Response(r, 200));
    when(client.get(ITunesSearchAPI().lookupURLByBundleId('com.google.Maps')))
        .thenAnswer((_) async => http.Response(r, 200));
    when(client.get(
            ITunesSearchAPI().lookupURLByBundleId('com.larryaasen.upgrader')))
        .thenAnswer((_) async => http.Response(r, 200));

    return client;
  }
}
