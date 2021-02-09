/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:convert';

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
  http.Client client = http.Client();

  bool debugEnabled = false;

  /// Look up by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  Future<Map> lookupByBundleId(String bundleId, {String country = 'US'}) async {
    if (bundleId == null || bundleId.isEmpty) {
      return null;
    }

    final url = lookupURLByBundleId(bundleId, country: country);
    if (debugEnabled) {
      print('upgrader: download: $url');
    }

    final response = await client.get(url);
    if (debugEnabled) {
      if (response == null) {
        print('upgrader: response empty');
      } else {
        print('upgrader: response statusCode: ${response.statusCode}');
      }
    }

    if (response == null) {
      return null;
    }

    final decodedResults = _decodeResults(response.body);
    return decodedResults;
  }

  /// Look up by id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLById('585027354');```
  /// ```lookupURLById('585027354', country: 'FR');```
  Future<Map> lookupById(String id, {String country = 'US'}) async {
    if (id == null || id.isEmpty) {
      return null;
    }

    final url = lookupURLById(id, country: country);
    final response = await client.get(url);

    final decodedResults = _decodeResults(response.body);
    return decodedResults;
  }

  /// Look up URL by bundle id.
  /// Example: look up Google Maps iOS App:
  /// ```lookupURLByBundleId('com.google.Maps');```
  /// ```lookupURLByBundleId('com.google.Maps', country: 'FR');```
  Uri lookupURLByBundleId(String bundleId, {String country = 'US'}) {
    if (bundleId == null || bundleId.isEmpty) {
      return null;
    }

    return lookupURLByQSP({'bundleId': bundleId, 'country': country});
  }

  /// Look up URL by id.
  /// Example: look up Jack Johnson by iTunes ID: ```lookupURLById('909253');```
  /// Example: look up Google Maps iOS App: ```lookupURLById('585027354');```
  /// Example: look up Google Maps iOS App: ```lookupURLById('585027354', country: 'FR');```
  Uri lookupURLById(String id, {String country = 'US'}) {
    if (id == null || id.isEmpty) {
      return null;
    }

    return lookupURLByQSP({'id': id, 'country': country});
  }

  /// Look up URL by QSP.
  Uri lookupURLByQSP(Map<String, String> qsp) {
    if (qsp == null || qsp.isEmpty) {
      return null;
    }

    final parameters = <String>[];
    qsp.forEach((key, value) => parameters.add('$key=$value'));
    final finalParameters = parameters.join('&');

    return Uri.parse('$lookupPrefixURL?$finalParameters');
  }

  Map _decodeResults(String jsonResponse) {
    if (jsonResponse != null && jsonResponse.isNotEmpty) {
      final decodedResults = json.decode(jsonResponse);
      if (decodedResults is Map) {
        final resultCount = decodedResults['resultCount'];
        if (resultCount == 0) {
          if (debugEnabled) {
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

class ITunesResults {
  /// Return field bundleId from iTunes results.
  static String bundleId(Map response) {
    var value;
    try {
      value = response['results'][0]['bundleId'];
    } catch (e) {
      print('upgrader.ITunesResults.bundleId: $e');
    }
    return value;
  }

  /// Return field currency from iTunes results.
  static String currency(Map response) {
    var value;
    try {
      value = response['results'][0]['currency'];
    } catch (e) {
      print('upgrader.ITunesResults.currency: $e');
    }
    return value;
  }

  /// Return field trackViewUrl from iTunes results.
  static String trackViewUrl(Map response) {
    var value;
    try {
      value = response['results'][0]['trackViewUrl'];
    } catch (e) {
      print('upgrader.ITunesResults.trackViewUrl: $e');
    }
    return value;
  }

  /// Return field version from iTunes results.
  static String version(Map response) {
    var value;
    try {
      value = response['results'][0]['version'];
    } catch (e) {
      print('upgrader.ITunesResults.version: $e');
    }
    return value;
  }
}
