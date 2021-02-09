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

    expect(
        iTunes.lookupURLByBundleId('com.google.Maps'),
        equals(Uri.parse(
            'https://itunes.apple.com/lookup?bundleId=com.google.Maps&country=US')));
    expect(
        iTunes.lookupURLById('585027354'),
        equals(Uri.parse(
            'https://itunes.apple.com/lookup?id=585027354&country=US')));
    expect(
        iTunes.lookupURLByQSP({'id': '909253', 'entity': 'album'}),
        equals(Uri.parse(
            'https://itunes.apple.com/lookup?id=909253&entity=album')));
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

  test('testing lookupByBundleId unknown app', () async {
    final client = MockClient.setupMockClient();
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupByBundleId('com.google.MyApp');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 0);
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
    expect(result0['currency'], 'USD');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
    expect(ITunesResults.currency(response), 'USD');
  });

  test('testing lookupById FR', () async {
    final client = MockClient.setupMockClient(country: 'FR');
    final iTunes = ITunesSearchAPI();
    iTunes.client = client;

    final response = await iTunes.lookupById('585027354', country: 'FR');
    expect(response, isInstanceOf<Map>());
    final results = response['results'];
    expect(results, isNotNull);
    expect(results.length, 1);
    final result0 = results[0];
    expect(result0, isNotNull);
    expect(result0['bundleId'], 'com.google.Maps');
    expect(result0['version'], '5.6');
    expect(result0['currency'], 'EUR');
    expect(ITunesResults.bundleId(response), 'com.google.Maps');
    expect(ITunesResults.version(response), '5.6');
    expect(ITunesResults.currency(response), 'EUR');
  });
}
