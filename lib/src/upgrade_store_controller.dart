// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'dart:async';

import 'package:version/version.dart';

import 'appcast.dart';
import 'itunes_search_api.dart';
import 'play_store_search_api.dart';
import 'upgrade_os.dart';
import 'upgrade_state.dart';
import 'upgrader_version_info.dart';

abstract class UpgraderStore {
  Future<UpgraderVersionInfo> getVersionInfo(
      {required UpgraderState state,
      required Version installedVersion,
      required String? country,
      required String? language});
}

class UpgraderAppStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required UpgraderState state,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    if (state.packageInfo == null) return UpgraderVersionInfo();

    String? appStoreListingURL;
    Version? appStoreVersion;
    bool? isCriticalUpdate;
    Version? minAppVersion;
    String? releaseNotes;

    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = state.debugLogging;
    iTunes.client = state.client;
    iTunes.clientHeaders = state.clientHeaders;
    final response = await (iTunes
        .lookupByBundleId(state.packageInfo!.packageName, country: country));

    if (response != null) {
      final version = iTunes.version(response);
      if (version != null) {
        try {
          appStoreVersion = Version.parse(version);
        } catch (e) {
          if (state.debugLogging) {
            print(
                'upgrader: UpgraderAppStore.appStoreVersion "$version" exception: $e');
          }
        }
      }
      appStoreListingURL = iTunes.trackViewUrl(response);
      releaseNotes ??= iTunes.releaseNotes(response);
      minAppVersion = iTunes.minAppVersion(response);
      if (minAppVersion != null) {
        if (state.debugLogging) {
          print('upgrader: UpgraderAppStore.minAppVersion: $minAppVersion');
        }
      }
    }

    final versionInfo = UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreListingURL: appStoreListingURL,
      appStoreVersion: appStoreVersion,
      isCriticalUpdate: isCriticalUpdate,
      minAppVersion: minAppVersion,
      releaseNotes: releaseNotes,
    );
    if (state.debugLogging) {
      print('upgrader: UpgraderAppStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

class UpgraderPlayStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required UpgraderState state,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    if (state.packageInfo == null) return UpgraderVersionInfo();
    final id = state.packageInfo!.packageName;
    final playStore = PlayStoreSearchAPI(
        client: state.client, clientHeaders: state.clientHeaders);
    playStore.debugLogging = state.debugLogging;

    String? appStoreListingURL;
    Version? appStoreVersion;
    bool? isCriticalUpdate;
    Version? minAppVersion;
    String? releaseNotes;

    final response =
        await playStore.lookupById(id, country: country, language: language);
    if (response != null) {
      final version = playStore.version(response);
      if (version != null) {
        try {
          appStoreVersion = Version.parse(version);
        } catch (e) {
          if (state.debugLogging) {
            print(
                'upgrader: UpgraderPlayStore.appStoreVersion "$version" exception: $e');
          }
        }
      }

      appStoreListingURL ??=
          playStore.lookupURLById(id, language: language, country: country);
      releaseNotes ??= playStore.releaseNotes(response);
      final mav = playStore.minAppVersion(response);
      if (mav != null) {
        try {
          final minVersion = mav.toString();
          minAppVersion = Version.parse(minVersion);

          if (state.debugLogging) {
            print('upgrader: UpgraderPlayStore.minAppVersion: $minAppVersion');
          }
        } catch (e) {
          if (state.debugLogging) {
            print('upgrader: UpgraderPlayStore.minAppVersion exception: $e');
          }
        }
      }
    }

    final versionInfo = UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreListingURL: appStoreListingURL,
      appStoreVersion: appStoreVersion,
      isCriticalUpdate: isCriticalUpdate,
      minAppVersion: minAppVersion,
      releaseNotes: releaseNotes,
    );
    if (state.debugLogging) {
      print('upgrader: UpgraderPlayStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

class UpgraderAppcastStore extends UpgraderStore {
  UpgraderAppcastStore({
    required this.appcastURL,
    this.appcast,
  });

  final String appcastURL;
  final Appcast? appcast;

  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required UpgraderState state,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    String? appStoreListingURL;
    Version? appStoreVersion;
    bool? isCriticalUpdate;
    String? releaseNotes;

    final localAppcast = appcast ??
        Appcast(
            client: state.client,
            clientHeaders: state.clientHeaders,
            upgraderDevice: state.upgraderDevice,
            upgraderOS: state.upgraderOS);
    await localAppcast.parseAppcastItemsFromUri(appcastURL);
    if (state.debugLogging) {
      var count = localAppcast.items == null ? 0 : localAppcast.items!.length;
      print('upgrader: UpgraderAppcastStore item count: $count');
    }
    final criticalUpdateItem = localAppcast.bestCriticalItem();
    final criticalVersion = criticalUpdateItem?.versionString ?? '';

    final bestItem = localAppcast.bestItem();
    if (bestItem != null &&
        bestItem.versionString != null &&
        bestItem.versionString!.isNotEmpty) {
      if (state.debugLogging) {
        print('upgrader: UpgraderAppcastStore best item version: '
            '${bestItem.versionString}');
        print('upgrader: UpgraderAppcastStore critical update item version: '
            '${criticalUpdateItem?.versionString}');
      }

      try {
        if (criticalVersion.isNotEmpty &&
            installedVersion < Version.parse(criticalVersion)) {
          isCriticalUpdate = true;
        }
      } catch (e) {
        if (state.debugLogging) {
          print(
              'upgrader: UpgraderAppcastStore: getVersionInfo could not parse version info $e');
        }
      }

      if (bestItem.versionString != null) {
        try {
          appStoreVersion = Version.parse(bestItem.versionString!);
        } catch (e) {
          if (state.debugLogging) {
            print(
                'upgrader: UpgraderAppcastStore: best item version could not be parsed: '
                '${bestItem.versionString}');
          }
        }
      }

      appStoreListingURL = bestItem.fileURL;
      releaseNotes = bestItem.itemDescription;
    }

    final versionInfo = UpgraderVersionInfo(
      installedVersion: installedVersion,
      appStoreListingURL: appStoreListingURL,
      appStoreVersion: appStoreVersion,
      isCriticalUpdate: isCriticalUpdate,
      releaseNotes: releaseNotes,
    );
    if (state.debugLogging) {
      print('upgrader: UpgraderAppcastStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

/// A controller that provides the store details for each platform.
class UpgraderStoreController {
  /// Creates a controller that provides the store details for each platform.
  UpgraderStoreController({
    this.onAndroid = onAndroidStore,
    this.onFuchsia,
    this.oniOS = onIOSStore,
    this.onLinux,
    this.onMacOS,
    this.onWeb,
    this.onWindows,
  });

  final UpgraderStore Function()? onAndroid;
  final UpgraderStore Function()? onFuchsia;
  final UpgraderStore Function()? oniOS;
  final UpgraderStore Function()? onLinux;
  final UpgraderStore Function()? onMacOS;
  final UpgraderStore Function()? onWeb;
  final UpgraderStore Function()? onWindows;

  UpgraderStore? getUpgraderStore(UpgraderOS upgraderOS) {
    switch (upgraderOS.currentOSType) {
      case UpgraderOSType.android:
        return onAndroid?.call();
      case UpgraderOSType.fuchsia:
        return onFuchsia?.call();
      case UpgraderOSType.ios:
        return oniOS?.call();
      case UpgraderOSType.linux:
        return onLinux?.call();
      case UpgraderOSType.macos:
        return onMacOS?.call();
      case UpgraderOSType.web:
        return onWeb?.call();
      case UpgraderOSType.windows:
        return onWindows?.call();
    }
  }

  static UpgraderStore onAndroidStore() => UpgraderPlayStore();
  static UpgraderStore onIOSStore() => UpgraderAppStore();
}
