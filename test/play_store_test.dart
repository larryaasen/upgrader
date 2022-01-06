/*
 * Copyright (c) 2019-2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import 'mock_play_store_client.dart';

void main() {
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
        playStore.lookupURLById('com.kotoko.express'),
        equals(
            'https://play.google.com/store/apps/details?id=com.kotoko.express'));
  }, skip: false);

  test('testing lookupById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI();
    playStore.client = client;

    final response = await playStore.lookupById('com.kotoko.express');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '1.23.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);
  }, skip: false);

  test('testing release notes', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI();
    playStore.client = client;

    final response = await playStore.lookupById('com.testing.test2');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response!),
        'Minor updates and improvements.');
    expect(PlayStoreResults.version(response), '2.0.2');
    expect(PlayStoreResults.description(response)?.length, greaterThan(10));
  }, skip: false);

  test('testing PlayStoreResults', () async {
    expect(PlayStoreResults(), isNotNull);
    expect(PlayStoreResults.releaseNotes(Document()), isNull);
    expect(PlayStoreResults.version(Document()), isNull);
  }, skip: false);

  /// Helper method
  Document resDesc(String description) {
    final html =
        '<div class="W4P4ne">hello<div class="PHBdkd">inside<div class="DWPxHb">$description</div></div></div>';
    return Document.html(html);
  }

  /// Helper method
  String? pmav(Document response) {
    final mav = PlayStoreResults.minAppVersion(response);
    return mav?.toString();
  }

  test('testing minAppVersion', () async {
    expect(pmav(resDesc('test [:mav: 1.2.3]')), '1.2.3');
    expect(pmav(resDesc('test [:mav:1.2.3]')), '1.2.3');
    expect(pmav(resDesc('test [:mav:1.2.3 ]')), '1.2.3');
    expect(pmav(resDesc('test [:mav: 1]')), '1.0.0');
    expect(pmav(resDesc('[:mav: 0.9.9+4]')), '0.9.9+4');
    expect(pmav(resDesc('[:mav: 1.0.0-5.2.pre]')), '1.0.0-5.2.pre');
    expect(pmav(Document()), isNull);
    expect(pmav(resDesc('test')), isNull);
    expect(pmav(resDesc('test [:mav:]')), isNull);
    expect(pmav(resDesc('test [:mv: 1.2.3]')), isNull);
  }, skip: false);
}
