/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

// TODO: refactor the two store API classes to use more shared code.

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
    final url = Uri.https(playStorePrefixURL, '/store/apps/details', {'id': id})
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
  static RegExp releaseNotesSpan = RegExp(r'>(.*?)</span>');

  /// Return field description from Play Store results.
  static String? description(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final descriptionElement = sectionElements[0];
      final description = descriptionElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb')
          ?.text;
      return description;
    } catch (e) {
      return redesignedDescription(response);
    }
  }

  /// Return field description from Redesigned Play Store results.
  static String? redesignedDescription(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('bARER');
      final descriptionElement = sectionElements.last;
      final description = descriptionElement.text;
      return description;
    } catch (e) {
      print('upgrader: PlayStoreResults.redesignedDescription exception: $e');
    }
    return null;
  }

  /// Return the minimum app version taken from the tag in the description field
  /// from the store response. The format is: [:mav: 1.2.3].
  /// Returns version, such as 1.2.3, or null.
  static Version? minAppVersion(Document response, {String tagName = 'mav'}) {
    Version? version;
    try {
      final description = PlayStoreResults.description(response);
      if (description != null) {
        const regExpSource = r'\[\:mav\:[\s]*(?<version>[^\s]+)[\s]*\]';
        final regExp = RegExp(regExpSource, caseSensitive: false);
        final match = regExp.firstMatch(description);
        final mav = match?.namedGroup('version');
        // Verify version string using class Version
        version = mav != null ? Version.parse(mav) : null;
      }
    } on Exception catch (e) {
      print('upgrader.PlayStoreResults.minAppVersion : $e');
    }
    return version;
  }

  /// Returns field releaseNotes from Play Store results. When there are no
  /// release notes, the main app description is used.
  static String? releaseNotes(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final releaseNotesElement = sectionElements.firstWhere(
          (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
          orElse: () => sectionElements[0]);

      Element? rawReleaseNotes = releaseNotesElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb');
      String? innerHtml = rawReleaseNotes!.innerHtml.toString();
      String? releaseNotes = multilineReleaseNotes(innerHtml, rawReleaseNotes);

      return releaseNotes;
    } catch (e) {
      return redesignedReleaseNotes(response);
    }
  }

  /// Returns field releaseNotes from Redesigned Play Store results. When there are no
  /// release notes, the main app description is used.
  static String? redesignedReleaseNotes(Document response) {
    try {
      final sectionElements =
          response.querySelectorAll('[itemprop="description"]');

      Element? rawReleaseNotes = sectionElements.last;
      String? innerHtml = rawReleaseNotes.innerHtml.toString();
      String? releaseNotes = multilineReleaseNotes(innerHtml, rawReleaseNotes);

      return releaseNotes;
    } catch (e) {
      print('upgrader: PlayStoreResults.redesignedReleaseNotes exception: $e');
    }
    return null;
  }

  static String? multilineReleaseNotes(
      String innerHtml, Element rawReleaseNotes) {
    String? releaseNotes;

    if (releaseNotesSpan.hasMatch(innerHtml)) {
      releaseNotes =
          releaseNotesSpan.firstMatch(innerHtml.toString())!.group(1);
      // Detect default multiline replacement
      releaseNotes = releaseNotes!.replaceAll('<br>', '\n');
    } else {
      /// Fallback to normal method
      releaseNotes = rawReleaseNotes.text;
    }

    return releaseNotes;
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
      // storeVersion might be: 'Varies with device', which is not a valid version.
      version = Version.parse(storeVersion).toString();
    } catch (e) {
      return redesignedVersion(response);
    }

    return version;
  }

  /// Return field version from Redesigned Play Store results.
  static String? redesignedVersion(Document response) {
    String? version;
    try {
      const patternName = ",\"name\":\"";
      const patternVersion = ",[[[\"";
      const patternCallback = "AF_initDataCallback";
      const patternEndOfString = "\"";

      final scripts = response.getElementsByTagName("script");
      final infoElements =
          scripts.where((element) => element.text.contains(patternName));
      final additionalInfoElements =
          scripts.where((element) => element.text.contains(patternCallback));
      final additionalInfoElementsFiltered = additionalInfoElements
          .where((element) => element.text.contains(patternVersion));

      final nameElement = infoElements.first.text;
      final storeNameStartIndex =
          nameElement.indexOf(patternName) + patternName.length;
      final storeNameEndIndex = storeNameStartIndex +
          nameElement
              .substring(storeNameStartIndex)
              .indexOf(patternEndOfString);
      final storeName =
          nameElement.substring(storeNameStartIndex, storeNameEndIndex);

      final versionElement = additionalInfoElementsFiltered
          .where((element) => element.text.contains("\"$storeName\""))
          .first
          .text;
      final storeVersionStartIndex =
          versionElement.lastIndexOf(patternVersion) + patternVersion.length;
      final storeVersionEndIndex = storeVersionStartIndex +
          versionElement
              .substring(storeVersionStartIndex)
              .indexOf(patternEndOfString);
      final storeVersion = versionElement.substring(
          storeVersionStartIndex, storeVersionEndIndex);

      // storeVersion might be: 'Varies with device', which is not a valid version.
      version = Version.parse(storeVersion).toString();
    } catch (e) {
      print('upgrader: PlayStoreResults.redesignedVersion exception: $e');
    }

    return version;
  }
}
