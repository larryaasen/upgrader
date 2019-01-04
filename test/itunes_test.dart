/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';
import 'mockclient.dart';

void main() {
  test('testing ITunesSearchAPI properties', () async {
    final iTunes = ITunesSearchAPI();
    expect(iTunes.debugEnabled, equals(false));
    iTunes.debugEnabled = true;
    expect(iTunes.debugEnabled, equals(true));
    expect(iTunes.iTunesDocumentationURL.length, greaterThan(0));
    expect(iTunes.lookupPrefixURL.length, greaterThan(0));
    expect(iTunes.searchPrefixURL.length, greaterThan(0));

    expect(iTunes.lookupURLByBundleId('com.google.Maps'),
        equals('https://itunes.apple.com/lookup?bundleId=com.google.Maps'));
    expect(iTunes.lookupURLById('585027354'),
        equals('https://itunes.apple.com/lookup?id=585027354'));
    expect(iTunes.lookupURLByQSP({'id': '909253', 'entity': 'album'}),
        equals('https://itunes.apple.com/lookup?id=909253&entity=album'));
  });

  test('testing lookupByBundleId', () async {
    final client = MockClient.setupMockClient();
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupByBundleId('com.google.Maps');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 1);
    final result0 = results[0];
    expect(result0, isNotNull);
    expect(result0['bundleId'], 'com.google.Maps');
    expect(result0['version'], '5.6');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
  });

  test('testing lookupById', () async {
    final client = MockClient.setupMockClient();
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupById('585027354');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 1);
    final result0 = results[0];
    expect(result0, isNotNull);
    expect(result0['bundleId'], 'com.google.Maps');
    expect(result0['version'], '5.6');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
  });
}
