/*
 * Copyright (c) 2019-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:upgrader/upgrader.dart';
import 'package:version/version.dart';

import 'mock_play_store_client.dart';

/// Helper method
String? pmav(Document response,
    {String tagRES = r'\[\:mav\:[\s]*(?<version>[^\s]+)[\s]*\]'}) {
  final mav =
      PlayStoreSearchAPI().minAppVersion(response, tagRegExpSource: tagRES);
  return mav?.toString();
}

void main() {
  test('testing version assumptions', () async {
    expect(() => Version.parse(''), throwsA(isA<FormatException>()));
    expect(() => Version.parse('Varies with device'),
        throwsA(isA<FormatException>()));

    expect(Version.parse('1.2.3').toString(), '1.2.3');
    expect(Version.parse('1.2.3+1').toString(), '1.2.3+1');
    expect(Version.parse('0.0.0').toString(), '0.0.0');
    expect(Version.parse('0.0.0+1').toString(), '0.0.0+1');

    final version1 = Version.parse('1.2.3+1');
    final version2 = Version.parse('1.2.3+2');
    expect(version1 == version2, isTrue);
  }, skip: false);

  test('testing PlayStoreSearchAPI properties', () async {
    final playStore = PlayStoreSearchAPI();
    expect(playStore.debugLogging, equals(false));
    playStore.debugLogging = true;
    expect(playStore.debugLogging, equals(true));
    expect(playStore.playStorePrefixURL.length, greaterThan(0));

    expect(
        playStore.lookupURLById('com.kotoko.express'),
        startsWith(
            'https://play.google.com/store/apps/details?id=com.kotoko.express&gl=US&hl=en&_cb='));
  }, skip: false);

  test('testing lookupById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);
    expect(() async => await playStore.lookupById(''), throwsAssertionError);

    final response = await playStore.lookupById('com.kotoko.express');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(
        playStore.releaseNotes(response!), 'Minor updates and improvements.');
    expect(playStore.version(response), '1.23.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);

    final document1 = await playStore.lookupById('com.testing.test4');
    expect(document1, isNotNull);
    expect(document1, isInstanceOf<Document>());

    final document2 =
        await playStore.lookupById('com.testing.test4', country: 'JP');
    expect(document2, isNull);
    final document3 =
        await playStore.lookupById('com.testing.test4', useCacheBuster: false);
    expect(document3, isNotNull);
  }, skip: false);

  test('testing lookupURLById', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);
    expect(() => playStore.lookupURLById(''), throwsAssertionError);
    expect(
        playStore.lookupURLById('com.testing.test1')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&gl=US&hl=en&_cb=17'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: null)!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&hl=en&_cb=17'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: '')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&hl=en&_cb=17'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', country: 'IN')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&gl=IN&hl=en&_cb=17'),
        equals(true));
    expect(
        playStore.lookupURLById('com.testing.test1', language: 'es')!.startsWith(
            'https://play.google.com/store/apps/details?id=com.testing.test1&gl=US&hl=es&_cb=17'),
        equals(true));
    expect(
        playStore
            .lookupURLById('com.testing.test1',
                country: 'IN', useCacheBuster: false)!
            .startsWith(
                'https://play.google.com/store/apps/details?id=com.testing.test1&gl=IN&hl=en'),
        equals(true));
  }, skip: false);

  test('testing lookupById with redesignedVersion', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test4');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(
        playStore.releaseNotes(response!), 'Minor updates and improvements.');
    expect(playStore.version(response), '2.3.0');
    expect(playStore.description(response)?.length, greaterThan(10));
    expect(
        pmav(response,
            tagRES:
                r'\[\Minimum supported app version\:[\s]*(?<version>[^\s]+)[\s]*\]'),
        '2.0.0');

    expect(await playStore.lookupById('com.not.a.valid.application'), isNull);
  }, skip: false);

  test('testing release notes', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test2');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(
        playStore.releaseNotes(response!), 'Minor updates and improvements.');
    expect(playStore.version(response), '2.0.2');
    expect(playStore.description(response)?.length, greaterThan(10));
  }, skip: false);

  test('testing release notes <br>', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test3');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(playStore.releaseNotes(response!),
        'Minor updates and improvements.\nAgain.\nAgain.');
    expect(playStore.version(response), '2.0.2');
    expect(playStore.description(response)?.length, greaterThan(10));
  }, skip: false);

  test('testing release notes <br> 2', () async {
    final client = await MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI(client: client);

    final response = await playStore.lookupById('com.testing.test5');
    expect(response, isNotNull);
    expect(response, isInstanceOf<Document>());

    expect(playStore.releaseNotes(response!),
        'Minor updates and improvements.\nAgain.\nAgain.');
    expect(playStore.version(response), '2.0.2');
    expect(playStore.description(response)?.length, greaterThan(10));
  }, skip: false);

  /// Helper method
  Document resDesc(String description) {
    final html =
        '<div class="W4P4ne">hello<div class="PHBdkd">inside<div class="DWPxHb">$description</div></div></div>';
    return Document.html(html);
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

  test('testing minAppVersion mav tag', () async {
    expect(pmav(resDesc('test [:mav: 1.2.3]'), tagRES: 'ddd'), isNull);
    expect(pmav(resDesc('test [:mav: a.b.c]')), isNull);
    expect(
        pmav(resDesc('test [:ddd: 1.2.3]'),
            tagRES: r'\[\:ddd\:[\s]*(?<version>[^\s]+)[\s]*\]'),
        '1.2.3');
    expect(
        pmav(resDesc('test [Minimum supported app version: 4.5.6+1]'),
            tagRES:
                r'\[\Minimum supported app version\:[\s]*(?<version>[^\s]+)[\s]*\]'),
        '4.5.6+1');
  });
}
