/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

class PlayStoreSearchAPI {
  PlayStoreSearchAPI({http.Client? client}) : client = client ?? http.Client();

  /// Play Store Search Api URL
  final String playStorePrefixURL = 'play.google.com';

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client? client;

  /// Enable print statements for debugging.
  bool debugLogging = false;

  /// Look up by id.
  Future<Document?> lookupById(String id,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) async {
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    final url = lookupURLById(id,
        country: country, language: language, useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('upgrader: lookupById url: $url');
    }

    try {
      final response = await client!.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (debugLogging) {
          print(
              'upgrader: Can\'t find an app in the Play Store with the id: $id');
        }
        return null;
      }

      // Uncomment for creating unit test input files.
      // final file = io.File('file.txt');
      // await file.writeAsBytes(response.bodyBytes);

      final decodedResults = _decodeResults(response.body);

      return decodedResults;
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader: lookupById exception: $e');
      }
      return null;
    }
  }

  String? lookupURLById(String id,
      {String? country = 'US',
      String? language = 'en',
      bool useCacheBuster = true}) {
    assert(id.isNotEmpty);
    if (id.isEmpty) return null;

    Map<String, dynamic> parameters = {'id': id};
    if (country != null && country.isNotEmpty) {
      parameters['gl'] = country;
    }
    if (language != null && language.isNotEmpty) {
      parameters['hl'] = language;
    }
    if (useCacheBuster) {
      parameters['_cb'] = DateTime.now().microsecondsSinceEpoch.toString();
    }
    final url = Uri.https(playStorePrefixURL, '/store/apps/details', parameters)
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

extension PlayStoreResults on PlayStoreSearchAPI {
  static RegExp releaseNotesSpan = RegExp(r'>(.*?)</span>');

  /// Return field description from Play Store results.
  String? description(Document response) {
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
  String? redesignedDescription(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('bARER');
      final descriptionElement = sectionElements.last;
      final description = descriptionElement.text;
      return description;
    } catch (e) {
      if (debugLogging) {
        print('upgrader: PlayStoreResults.redesignedDescription exception: $e');
      }
    }
    return null;
  }

  /// Return the minimum app version taken from a tag in the description field from the store response.
  /// The [tagRegExpSource] is used to represent the format of a tag using a regular expression.
  /// The format in the description by default is like this: `[Minimum supported app version: 1.2.3]`, which
  /// returns the version `1.2.3`. If there is no match, it returns null.
  Version? minAppVersion(
    Document response, {
    String tagRegExpSource =
        r'\[\Minimum supported app version\:[\s]*(?<version>[^\s]+)[\s]*\]',
  }) {
    Version? version;
    try {
      final desc = description(response);
      if (desc != null) {
        final regExp = RegExp(tagRegExpSource, caseSensitive: false);
        final match = regExp.firstMatch(desc);
        final mav = match?.namedGroup('version');

        if (mav != null) {
          try {
            // Verify version string using class Version
            version = Version.parse(mav);
          } on Exception catch (e) {
            if (debugLogging) {
              print(
                  'upgrader: PlayStoreResults.minAppVersion: mav=$mav, tag=$tagRegExpSource, error=$e');
            }
          }
        }
      }
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader.PlayStoreResults.minAppVersion : $e');
      }
    }
    return version;
  }

  /// Returns field releaseNotes from Play Store results. When there are no
  /// release notes, the main app description is used.
  String? releaseNotes(Document response) {
    try {
      final sectionElements = response.getElementsByClassName('W4P4ne');
      final releaseNotesElement = sectionElements.firstWhere(
          (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
          orElse: () => sectionElements[0]);

      final rawReleaseNotes = releaseNotesElement
          .querySelector('.PHBdkd')
          ?.querySelector('.DWPxHb');
      final releaseNotes = rawReleaseNotes == null
          ? null
          : multilineReleaseNotes(rawReleaseNotes);

      return releaseNotes;
    } catch (e) {
      return redesignedReleaseNotes(response);
    }
  }

  /// Returns field releaseNotes from Redesigned Play Store results. When there are no
  /// release notes, the main app description is used.
  String? redesignedReleaseNotes(Document response) {
    try {
      final sectionElements =
          response.querySelectorAll('[itemprop="description"]');

      final rawReleaseNotes = sectionElements.last;
      final releaseNotes = multilineReleaseNotes(rawReleaseNotes);
      return releaseNotes;
    } catch (e) {
      if (debugLogging) {
        print(
            'upgrader: PlayStoreResults.redesignedReleaseNotes exception: $e');
      }
    }
    return null;
  }

  String? multilineReleaseNotes(Element rawReleaseNotes) {
    final innerHtml = rawReleaseNotes.innerHtml;
    String? releaseNotes = innerHtml;

    if (releaseNotesSpan.hasMatch(innerHtml)) {
      releaseNotes = releaseNotesSpan.firstMatch(innerHtml)!.group(1);
    }
    // Detect default multiline replacement
    releaseNotes = releaseNotes!.replaceAll('<br>', '\n');

    return releaseNotes;
  }

  /// Return field version from Play Store results.
  String? version(Document response) {
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
  String? redesignedVersion(Document response) {
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
      if (debugLogging) {
        print('upgrader: PlayStoreResults.redesignedVersion exception: $e');
      }
    }

    return version;
  }
}
