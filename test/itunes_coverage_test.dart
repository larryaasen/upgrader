// Copyright (c) 2026 Larry Aasen. All rights reserved.

import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  test('ITunesSearchAPI lookupByBundleId exception with debugLogging',
      () async {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    iTunes.client = MockClient((request) async {
      throw Exception('Mock error');
    });

    final response = await iTunes.lookupByBundleId('com.test.app');
    expect(response, isNull);
  });

  test('ITunesSearchAPI lookupById exception with debugLogging', () async {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    iTunes.client = MockClient((request) async {
      throw Exception('Mock error');
    });

    final response = await iTunes.lookupById('123456');
    expect(response, isNull);
  });

  test('ITunesSearchAPI empty results with debugLogging', () async {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    iTunes.client = MockClient((request) async {
      return http.Response('{"resultCount": 0, "results": []}', 200);
    });

    final response = await iTunes.lookupByBundleId('com.test.app');
    expect(response, isNull);
  });

  test('ITunesResults extension methods exceptions with debugLogging', () {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    final Map malformedResponse = {'results': 'not a list'};

    expect(iTunes.bundleId(malformedResponse), isNull);
    expect(iTunes.currency(malformedResponse), isNull);
    expect(iTunes.description(malformedResponse), isNull);
    expect(iTunes.releaseNotes(malformedResponse), isNull);
    expect(iTunes.trackViewUrl(malformedResponse), isNull);
    expect(iTunes.version(malformedResponse), isNull);
  });

  test('ITunesResults minAppVersion exception with debugLogging', () {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    final Map malformedResponse = {'results': 'not a list'};

    expect(iTunes.minAppVersion(malformedResponse), isNull);
  });

  test('ITunesResults minAppVersion invalid version string with debugLogging',
      () {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    final Map response = {
      'results': [
        {'description': '[:mav: invalid-version]'}
      ]
    };

    expect(iTunes.minAppVersion(response), isNull);
  });

  test('ITunesSearchAPI lookup debug logging', () async {
    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = true;
    iTunes.client = MockClient((request) async {
      return http.Response('{"resultCount": 1, "results": []}', 200);
    });

    // This triggers the "upgrader: download: ..." print
    await iTunes.lookupById('123');
  });
}
