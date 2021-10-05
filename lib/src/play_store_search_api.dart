/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

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

    final response = await client!.get(Uri.parse(url));

    if (response.statusCode != 200) {
      print('upgrader: Can\'t find an app in the Play Store with the id: $id');
      return null;
    }

    // Uncomment for creating unit test input files.
    // final file = io.File('file.txt');
    // await file.writeAsBytes(response.bodyBytes);

    final decodedResults = _decodeResults(response.body);

    return decodedResults;
  }

  String? lookupURLById(String id) {
    final url =
        Uri.https(playStorePrefixURL, '/store/apps/details', {'id': '$id'})
            .toString();

    return url;
  }

  Document? _decodeResults(String jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = parse(jsonResponse);
      return decodedResults;
    }
    return null;
  }
}

class PlayStoreResults {
  /// Returns field releaseNotes from Play Store results. When there are no
  /// release notes, the main app description is used.
  static String? releaseNotes(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final releaseNotesElement = sectionElements.firstWhere(
          (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
          orElse: () => sectionElements[0]);
      final releaseNotes = releaseNotesElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb')
          ?.text;

      return releaseNotes;
    } catch (e) {
      print('upgrader: PlayStoreResults.releaseNotes exception: $e');
    }
    return null;
  }

  /// Return field version from Play Store results.
  static String? version(Document response) {
    String? version;
    try {
      final additionalInfoElements = response.getElementsByClassName('hAyfc');
      final versionElement = additionalInfoElements.firstWhere(
        (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
      );
      final storeVersion = versionElement.querySelector('.htlgb')!.text;
      version = Version.parse(storeVersion).toString();
    } catch (e) {
      print('upgrader: PlayStoreResults.version exception: $e');
    }

    return version;
  }
}
