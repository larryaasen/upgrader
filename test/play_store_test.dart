/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import 'mock_play_store_client.dart';

void main() {
  final applicationId = 'com.kotoko.express';

  test('testing version assumptions', () async {
    expect(() => Version.parse(null), throwsA(isA<FormatException>()));
    expect(() => Version.parse(''), throwsA(isA<FormatException>()));
    expect(() => Version.parse('Varies with device'),
        throwsA(isA<FormatException>()));

    expect(Version.parse('1.2.3').toString(), '1.2.3');
    expect(Version.parse('1.2.3+1').toString(), '1.2.3+1');
  }, skip: false);

  test('testing PlayStoreSearchAPI properties', () async {
    final playStore = PlayStoreSearchAPI();
    expect(playStore.debugEnabled, equals(false));
    playStore.debugEnabled = true;
    expect(playStore.debugEnabled, equals(true));
    expect(playStore.playStorePrefixURL.length, greaterThan(0));

    expect(
        playStore.lookupURLById(applicationId),
        equals(
            'https://play.google.com/store/apps/details?id=com.kotoko.express'));
  }, skip: false);

  test('testing lookupById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI();
    playStore.client = client;

    final response = await playStore.lookupById(applicationId);
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '1.23.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);
  }, skip: false);

  test('testing PlayStoreResults', () async {
    expect(PlayStoreResults(), isNotNull);
    expect(PlayStoreResults.releaseNotes(Document()), isNull);
    expect(PlayStoreResults.version(Document()), isNull);
  }, skip: false);
}
