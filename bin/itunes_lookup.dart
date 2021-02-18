/*
 * Copyright (c) 2019 Larry Aasen. All rights reserved.
 */

/*
  Usage:
  $  dart itunes_lookup.dart bundleid=com.google.Maps
 */

import 'package:upgrader/src/itunes_search_api.dart';

void main(List<String> arguments) {
  final defaultLookupBundleId = 'com.google.Maps';
  var lookupBundleId = defaultLookupBundleId;

  if (arguments.length == 1) {
    final arg0 = arguments[0].split('=');
    if (arg0.length == 2) {
      final argName = arg0[0];
      final argValue = arg0[1];

      if (argName == 'bundleid') {
        lookupBundleId = argValue;
      }
    }
  }

  final iTunes = ITunesSearchAPI();
  iTunes.debugEnabled = true;
  final countryCode = 'US';
  final resultsFuture = iTunes.lookupByBundleId(
    lookupBundleId,
    country: countryCode,
  );
  resultsFuture.then((results) {
    final bundleId = ITunesResults.bundleId(results!);
    final trackViewUrl = ITunesResults.trackViewUrl(results);
    final version = ITunesResults.version(results);

    print('itunes_lookup bundleId: $bundleId');
    print('itunes_lookup trackViewUrl: $trackViewUrl');
    print('itunes_lookup version: $version');

    print('itunes_lookup all results:\n$results');
  });
}
