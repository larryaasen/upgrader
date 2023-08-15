/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:convert';
import 'package:version/version.dart';
import 'package:http/http.dart' as http;

class ITunesSearchAPI {
  /// iTunes Search API documentation URL
  final String iTunesDocumentationURL =
      'https://affiliate.itunes.apple.com/resources/documentation/itunes-store-web-service-search-api/';

  /// iTunes Lookup API URL
  final String lookupPrefixURL = 'https://itunes.apple.com/lookup';

  /// iTunes Search API URL
  final String searchPrefixURL = 'https://itunes.apple.com/search';

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client? client = http.Client();

  /// Enable print statements for debugging.
  bool debugLogging = false;

  /// Look up by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  Future<Map?> lookupByBundleId(String bundleId,
      {String? country = 'US', bool useCacheBuster = true}) async {
    assert(bundleId.isNotEmpty);
    if (bundleId.isEmpty) {
      return null;
    }

    final url = lookupURLByBundleId(bundleId,
        country: country ??= '', useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('upgrader: download: $url');
    }

    try {
      final response = await client!.get(Uri.parse(url));
      if (debugLogging) {
        print('upgrader: response statusCode: ${response.statusCode}');
      }

      final decodedResults = _decodeResults(response.body);
      return decodedResults;
    } catch (e) {
      if (debugLogging) {
        print('upgrader: lookupByBundleId exception: $e');
      }
      return null;
    }
  }

  /// Look up by id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLById('585027354');```
  /// ```lookupURLById('585027354', country: 'FR');```
  Future<Map?> lookupById(String id,
      {String country = 'US', bool useCacheBuster = true}) async {
    if (id.isEmpty) {
      return null;
    }

    final url =
        lookupURLById(id, country: country, useCacheBuster: useCacheBuster)!;
    if (debugLogging) {
      print('upgrader: download: $url');
    }
    try {
      final response = await client!.get(Uri.parse(url));
      final decodedResults = _decodeResults(response.body);
      return decodedResults;
    } catch (e) {
      if (debugLogging) {
        print('upgrader: lookupById exception: $e');
      }
      return null;
    }
  }

  /// Look up URL by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  String? lookupURLByBundleId(String bundleId,
      {String country = 'US', bool useCacheBuster = true}) {
    if (bundleId.isEmpty) {
      return null;
    }

    return lookupURLByQSP(
        {'bundleId': bundleId, 'country': country.toUpperCase()},
        useCacheBuster: useCacheBuster);
  }

  /// Look up URL by id.
  /// Example: look up Jack Johnson by iTunes ID: ```lookupURLById('909253');```
  /// Example: look up Google Maps iOS App: ```lookupURLById('585027354');```
  /// Example: look up Google Maps iOS App: ```lookupURLById('585027354', country: 'FR');```
  String? lookupURLById(String id,
      {String country = 'US', bool useCacheBuster = true}) {
    if (id.isEmpty) {
      return null;
    }

    return lookupURLByQSP({'id': id, 'country': country.toUpperCase()},
        useCacheBuster: useCacheBuster);
  }

  /// Look up URL by QSP.
  String? lookupURLByQSP(Map<String, String?> qsp,
      {bool useCacheBuster = true}) {
    if (qsp.isEmpty) {
      return null;
    }

    final parameters = <String>[];
    qsp.forEach((key, value) => parameters.add('$key=$value'));
    if (useCacheBuster) {
      parameters.add('_cb=${DateTime.now().microsecondsSinceEpoch.toString()}');
    }
    final finalParameters = parameters.join('&');

    return '$lookupPrefixURL?$finalParameters';
  }

  Map? _decodeResults(String jsonResponse) {
    if (jsonResponse.isNotEmpty) {
      final decodedResults = json.decode(jsonResponse);
      if (decodedResults is Map) {
        final resultCount = decodedResults['resultCount'];
        if (resultCount == 0) {
          if (debugLogging) {
            print(
                'upgrader.ITunesSearchAPI: results are empty: $decodedResults');
          }
        }
        return decodedResults;
      }
    }
    return null;
  }
}

extension ITunesResults on ITunesSearchAPI {
  /// Return field bundleId from iTunes results.
  String? bundleId(Map response) {
    String? value;
    try {
      value = response['results'][0]['bundleId'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.bundleId: $e');
      }
    }
    return value;
  }

  /// Return field currency from iTunes results.
  String? currency(Map response) {
    String? value;
    try {
      value = response['results'][0]['currency'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.currency: $e');
      }
    }
    return value;
  }

  /// Return field description from iTunes results.
  String? description(Map response) {
    String? value;
    try {
      value = response['results'][0]['description'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.description: $e');
      }
    }
    return value;
  }

  /// Return the minimum app version taken from the tag in the description field
  /// from the store response. The format is: [:mav: 1.2.3].
  /// Returns version, such as 1.2.3, or null.
  Version? minAppVersion(Map response, {String tagName = 'mav'}) {
    Version? version;
    try {
      final desc = description(response);
      if (desc != null) {
        String regExpSource = r"\[\:tagName\:[\s]*(?<version>[^\s]+)[\s]*\]";
        regExpSource = regExpSource.replaceAll(RegExp('tagName'), tagName);
        final regExp = RegExp(regExpSource, caseSensitive: false);
        final match = regExp.firstMatch(desc);
        final mav = match?.namedGroup('version');

        if (mav != null) {
          try {
            // Verify version string using class Version
            version = Version.parse(mav);
          } on Exception catch (e) {
            if (debugLogging) {
              print(
                  'upgrader: ITunesResults.minAppVersion: $tagName error: $e');
            }
          }
        }
      }
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.minAppVersion : $e');
      }
    }
    return version;
  }

  /// Return field releaseNotes from iTunes results.
  String? releaseNotes(Map response) {
    String? value;
    try {
      value = response['results'][0]['releaseNotes'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.releaseNotes: $e');
      }
    }
    return value;
  }

  /// Return field trackViewUrl from iTunes results.
  String? trackViewUrl(Map response) {
    String? value;
    try {
      value = response['results'][0]['trackViewUrl'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.trackViewUrl: $e');
      }
    }
    return value;
  }

  /// Return field version from iTunes results.
  String? version(Map response) {
    String? value;
    try {
      value = response['results'][0]['version'];
    } catch (e) {
      if (debugLogging) {
        print('upgrader.ITunesResults.version: $e');
      }
    }
    return value;
  }
}
