/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

/*
  Usage:
  $  dart playstore_lookup.dart id=com.google.android.apps.mapslite country=US
 */

import 'package:upgrader/src/play_store_search_api.dart';

void main(List<String> arguments) async {
  var lookupId = 'com.google.android.apps.mapslite';
  var lookupCountry = 'US';

  if (arguments.isNotEmpty) {
    final arg0 = arguments[0].split('=');
    if (arg0.length == 2) {
      final argName = arg0[0];
      final argValue = arg0[1];
      if (argName == 'id') {
        lookupId = argValue;
      }
    }

    if (arguments.length > 1) {
      final arg1 = arguments[1].split('=');
      if (arg1.length == 2) {
        final argName = arg1[0];
        final argValue = arg1[1];
        if (argName == 'country') {
          lookupCountry = argValue;
        }
      }
    }
  }

  final playStore = PlayStoreSearchAPI();
  playStore.debugLogging = true;

  final results = await playStore.lookupById(lookupId, country: lookupCountry);

  if (results == null) {
    print('playstore_lookup there are no results');
    return;
  }

  final description = playStore.description(results);
  final minAppVersion = playStore.minAppVersion(results);
  final releaseNotes = playStore.releaseNotes(results);
  final version = playStore.version(results);

  print('playstore_lookup description: $description');
  print('playstore_lookup minAppVersion: $minAppVersion');
  print('playstore_lookup releaseNotes: $releaseNotes');
  print('playstore_lookup version: $version');

  print('playstore_lookup all results:\n$results');
  return;
}
