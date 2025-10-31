/*
 * Copyright (c) 2021 William Kwabla. All rights reserved.
 */

import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';

class PlayStoreSearchAPI {
  PlayStoreSearchAPI({http.Client? client, this.clientHeaders})
      : client = client ?? http.Client();

  /// Play Store Search Api URL
  final String playStorePrefixURL = 'play.google.com';

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client? client;

  /// Provide the HTTP headers used by [client].
  final Map<String, String>? clientHeaders;

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
      final response =
          await client!.get(Uri.parse(url), headers: clientHeaders);
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

  /// Create a URL that points to the Play Store details for an app.
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
      final storeNameCleaned = storeName.replaceAll(r'\u0027', '\'');

      final versionElement = additionalInfoElementsFiltered
          .where((element) => element.text.contains("\"$storeNameCleaned\""))
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

      if (debugLogging) {
        print(
            'upgrader: PlayStoreResults.redesignedVersion: extracted storeVersion="$storeVersion"');
      }

      // storeVersion might be empty, null, or 'Varies with device', which is not a valid version.
      // Validate before parsing
      if (storeVersion.isEmpty) {
        return null;
      }

      // Try to parse the version string
      try {
        version = Version.parse(storeVersion).toString();
        if (debugLogging) {
          print(
              'upgrader: PlayStoreResults.redesignedVersion: successfully parsed version="$version"');
        }
      } on FormatException catch (e) {
        if (debugLogging) {
          print(
              'upgrader: PlayStoreResults.redesignedVersion: invalid version format "$storeVersion": $e');
        }
        // If version parsing failed, try alternative pattern (for regional pages)
        version = _parseVersionAlternative(response, debugLogging);
      }
    } catch (e) {
      if (debugLogging) {
        print('upgrader: PlayStoreResults.redesignedVersion exception: $e');
      }
      // If the main parsing failed, try alternative pattern (for regional pages)
      version = _parseVersionAlternative(response, debugLogging);
    }

    return version;
  }

  /// Alternative version parsing for regional Play Store pages (e.g., Korean, Bengali, Egypt)
  ///
  /// When the main parsing method fails on regional pages, this method tries multiple
  /// fallback patterns to extract version information from the Play Store JSON data.
  ///
  /// Patterns tried:
  /// 1. JSON key pattern: "XXX":[[["version" where XXX is a numeric key (common: 140-145)
  /// 2. Bracket pattern: ]]],"version" which appears in some regional variants
  String? _parseVersionAlternative(Document response, bool debugLogging) {
    try {
      final scripts = response.getElementsByTagName("script");

      // Pattern 1: Try common JSON data keys where version info appears (140-145)
      // These keys represent version data in Play Store's internal structure
      /*
       * The keys 140-145 were determined by inspecting the Play Store's page source and
       * network responses. In the Play Store's internal JSON data structure, the version
       * information for an app is often found under numeric keys in this range.
       * These keys are not documented by Google and may change if the Play Store's
       * internal structure changes. If version extraction fails in the future,
       * maintainers should re-examine the Play Store's page source or network traffic
       * to identify the new keys where version information is stored, and update this
       * list accordingly.
       */
      for (var key in [140, 141, 142, 143, 144, 145]) {
        final pattern = '"$key":[[["';
        const patternEndOfString = '"';

        final versionElements =
            scripts.where((element) => element.text.contains(pattern));

        if (versionElements.isNotEmpty) {
          final versionElement = versionElements.first.text;
          final versionStartIndex =
              versionElement.indexOf(pattern) + pattern.length;

          if (versionStartIndex >= pattern.length) {
            final versionEndIndex = versionStartIndex +
                versionElement
                    .substring(versionStartIndex)
                    .indexOf(patternEndOfString);

            if (versionEndIndex > versionStartIndex) {
              final storeVersion =
                  versionElement.substring(versionStartIndex, versionEndIndex);

              if (storeVersion.isNotEmpty) {
                // Try to parse the version string
                try {
                  final parsed = Version.parse(storeVersion);
                  if (debugLogging) {
                    print(
                        'upgrader: PlayStoreResults._parseVersionAlternative: found version="$storeVersion" with key=$key');
                  }
                  return parsed.toString();
                } on FormatException {
                  // This key didn't have a valid version, try next key
                  continue;
                }
              }
            }
          }
        }
      }

      // Pattern 2: Try bracket pattern ]]]," which appears in some Play Store variants
      // This pattern is found in certain regional pages (e.g., Egypt) where the version
      // is stored as ]]],"X.Y.Z",null,null...
      const bracketPattern = ']]],"';
      final regExp = RegExp(r'\]\]\],"(\d+\.\d+\.\d+)"');

      for (var script in scripts) {
        final scriptText = script.text;
        if (scriptText.contains(bracketPattern)) {
          final matches = regExp.allMatches(scriptText);
          for (var match in matches) {
            final storeVersion = match.group(1);
            if (storeVersion != null && storeVersion.isNotEmpty) {
              try {
                final parsed = Version.parse(storeVersion);
                if (debugLogging) {
                  print(
                      'upgrader: PlayStoreResults._parseVersionAlternative: found version="$storeVersion" with bracket pattern');
                }
                return parsed.toString();
              } on FormatException {
                // Not a valid version, try next match
                continue;
              }
            }
          }
        }
      }

      if (debugLogging) {
        print(
            'upgrader: PlayStoreResults._parseVersionAlternative: no valid version found in common patterns');
      }
      return null;
    } catch (e) {
      if (debugLogging) {
        print(
            'upgrader: PlayStoreResults._parseVersionAlternative exception: $e');
      }
      return null;
    }
  }
}
