/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:upgrader/upgrader.dart';

import 'mock_play_store_client.dart';

void main() {
  var applicationId = 'com.kotoko.express';
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
  });

  test('testing lookupById', () async {
    final client = MockPlayStoreSearchClient.setupMockClient();
    final playStore = PlayStoreSearchAPI();
    playStore.client = client;

    final response = await playStore.lookupById(applicationId);
    expect(response, isInstanceOf<Document>());

    expect(PlayStoreResults.releaseNotes(response),
        'Bug fixes and performance enhancements');
    expect(
        PlayStoreResults.trackViewUrl(applicationId),
        Uri.https(
                'play.google.com', '/store/apps/details', {'id': applicationId})
            .toString());
    expect(PlayStoreResults.version(response), '2.1.6');
  }, skip: false);
}
