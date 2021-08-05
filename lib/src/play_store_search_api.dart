/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class PlayStoreSearchAPI {
  /// Play Store Search Api URL
  final String playStorePrefixURL = 'play.google.com';

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client? client = http.Client();

  bool debugEnabled = false;

  /// Look up by id.
  Future<Document?> lookupById(String id) async {
    if (id.isEmpty) {
      return null;
    }

    final url = lookupURLById(id)!;

    final response = await http.get(url);

    if (response.statusCode != 200) {
      print('Can\'t find an app in the Play Store with the id: $id');
      return null;
    }

    final decodedResults = _decodeResults(response.body);

    return decodedResults;
  }

  Uri? lookupURLById(id) {
    final uri =
        Uri.https(playStorePrefixURL, '/store/apps/details', {'id': '$id'});

    return uri;
  }

  Document? _decodeResults(jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = parse(jsonResponse);

      return decodedResults;
    }
    return null;
  }
}

class PlayStoreResults {
  /// Return field releaseNotes from Play Store results.
  static String? releaseNotes(response) {
    final sectionElements = response.getElementsByClassName('W4P4ne');
    final releaseNotesElement = sectionElements.firstWhere(
      (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
    );
    final releaseNotes = releaseNotesElement
        .querySelector('.PHBdkd')
        ?.querySelector('.DWPxHb')
        ?.text;

    return releaseNotes;
  }

  /// Return field trackViewUrl from Play Store results.
  static String? trackViewUrl(id) {
    final uri =
        Uri.https('play.google.com', '/store/apps/details', {'id': '$id'})
            .toString();

    return uri;
  }

  /// Return field version from Play Store results.
  static String? version(response) {
    final additionalInfoElements = response.getElementsByClassName('hAyfc');
    final versionElement = additionalInfoElements.firstWhere(
      (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
    );

    final storeVersion = versionElement.querySelector('.htlgb')!.text;

    return storeVersion;
  }
}
