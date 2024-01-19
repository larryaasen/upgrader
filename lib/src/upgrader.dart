/*
 * Copyright (c) 2018-2023 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'appcast.dart';
import 'itunes_search_api.dart';
import 'play_store_search_api.dart';
import 'upgrade_os.dart';
import 'upgrade_messages.dart';

/// Signature of callbacks that have no arguments and return bool.
typedef BoolCallback = bool Function();

/// Signature of callbacks that have a bool argument and no return.
typedef VoidBoolCallback = void Function(bool value);

/// Signature of callback for willDisplayUpgrade. Includes display,
/// minAppVersion, installedVersion, and appStoreVersion.
typedef WillDisplayUpgradeCallback = void Function({
  required bool display,
  String? installedVersion,
  required UpgraderVersionInfo versionInfo,
});

/// The type of data in the stream.
typedef UpgraderEvaluateNeed = bool;

/// A class to define the configuration for the appcast. The configuration
/// contains two parts: a URL to the appcast, and a list of supported OS
/// names, such as "android", "fuchsia", "ios", "linux" "macos", "web", "windows".

// TODO: remove this class
class AppcastConfiguration {
  final List<String>? supportedOS;
  final String? url;

  AppcastConfiguration({
    this.supportedOS,
    this.url,
  });
}

/// Creates a shared instance of [Upgrader].
// TODO: maybe this should not be created as a global.
Upgrader _sharedInstance = Upgrader();

/// A class to configure the upgrade dialog.
class Upgrader with WidgetsBindingObserver {
  Upgrader({
    this.appcastConfig,
    this.appcast,
    this.messages,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
    this.willDisplayUpgrade,
    http.Client? client,
    this.countryCode,
    this.languageCode,
    this.minAppVersion,
    UpgraderStoreController? storeController,
    UpgraderOS? upgraderOS,
  })  : client = client ?? http.Client(),
        storeController = storeController ?? UpgraderStoreController(),
        upgraderOS = upgraderOS ?? UpgraderOS() {
    if (debugLogging) print("upgrader: instantiated.");
  }

  /// Provide an Appcast that can be replaced for mock testing.
  // TODO: remove this class
  final Appcast? appcast;

  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  /// When an appcast is configured for iOS, the iTunes lookup is not used.
  // TODO: remove this class
  final AppcastConfiguration? appcastConfig;

  /// The controller that provides the store details for each platform.
  final UpgraderStoreController storeController;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  /// The country code that will override the system locale. Optional.
  final String? countryCode;

  /// The country code that will override the system locale. Optional. Used only for Android.
  final String? languageCode;

  /// For debugging, always force the upgrade to be available.
  bool debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  bool debugDisplayOnce;

  /// Enable print statements for debugging.
  bool debugLogging;

  /// Duration until alerting user again
  final Duration durationUntilAlertAgain;

  /// The localized messages used for display in upgrader.
  UpgraderMessages? messages;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  String? minAppVersion;

  /// Provides information on which OS this code is running on.
  final UpgraderOS upgraderOS;

  /// Called when [Upgrader] determines that an upgrade may or may not be
  /// displayed. The [value] parameter will be true when it should be displayed,
  /// and false when it should not be displayed. One good use for this callback
  /// is logging metrics for your app.
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  bool _initCalled = false;
  PackageInfo? _packageInfo;
  PackageInfo? get packageInfo => _packageInfo;

  String? _installedVersion;
  Version? _updateAvailable;
  DateTime? _lastTimeAlerted;
  Version? _lastVersionAlerted;
  Version? _userIgnoredVersion;
  bool _hasAlerted = false;

  /// Track the initialization future so that [initialize] can be called multiple times.
  Future<bool>? _futureInit;

  /// A stream that provides a new value each time an evaluation should be performed.
  /// The values will always be null or true.
  Stream<UpgraderEvaluateNeed> get evaluationStream => _streamController.stream;
  final _streamController = StreamController<UpgraderEvaluateNeed>.broadcast();

  /// An evaluation should be performed.
  bool get evaluationReady => _evaluationReady;
  bool _evaluationReady = false;

  /// A shared instance of [Upgrader].
  static Upgrader get sharedInstance => _sharedInstance;

  static const notInitializedExceptionMessage =
      'upgrader: initialize() not called. Must be called first.';

  String? get currentAppStoreListingURL => _versionInfo?.appStoreListingURL;

  String? get currentAppStoreVersion =>
      _versionInfo?.appStoreVersion?.toString();

  String? get currentInstalledVersion => _installedVersion;

  String? get releaseNotes => _versionInfo?.releaseNotes;

  void installPackageInfo({PackageInfo? packageInfo}) {
    _packageInfo = packageInfo;
    _initCalled = false;
  }

  // void installAppStoreVersion(String version) => _appStoreVersion = version;

  // void installAppStoreListingURL(String url) => _appStoreListingURL = url;

  /// The latest version info for this app.
  UpgraderVersionInfo? _versionInfo;

  /// The latest version info for this app.
  UpgraderVersionInfo? get versionInfo => _versionInfo;

  /// Initialize [Upgrader] by getting saved preferences, getting platform package info, and getting
  /// released version info.
  Future<bool> initialize() async {
    if (debugLogging) print('upgrader: initialize called');

    if (_futureInit != null) return _futureInit!;

    _futureInit = Future(() async {
      if (debugLogging) print('upgrader: initializing');

      if (_initCalled) {
        assert(false, 'This should never happen.');
        return true;
      }
      _initCalled = true;

      await getSavedPrefs();

      if (debugLogging) print('upgrader: $upgraderOS');

      if (_packageInfo == null) {
        _packageInfo = await PackageInfo.fromPlatform();
        if (debugLogging) {
          print(
              'upgrader: package info packageName: ${_packageInfo!.packageName}');
          print('upgrader: package info appName: ${_packageInfo!.appName}');
          print('upgrader: package info version: ${_packageInfo!.version}');
        }
      }

      _installedVersion = _packageInfo!.version;

      _versionInfo = await updateVersionInfo();

      // Add an observer of application events, so that when the app returns
      // from the background, the version info is updated.
      WidgetsBinding.instance.addObserver(this);

      _evaluationReady = true;

      /// Trigger the stream to indicate an evaluation should be performed.
      /// The value will always be true.
      _streamController.add(true);

      return true;
    });
    return _futureInit!;
  }

  /// Remove any resources allocated.
  void dispose() {
    // Remove the observer of application events.
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Handle application events.
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    // When app has resumed from background.
    if (state == AppLifecycleState.resumed) {
      await updateVersionInfo();

      /// Trigger the stream to indicate another evaluation should be performed.
      /// The value will always be true.
      _streamController.add(true);
    }
  }

  /// Update the version info for this app.
  Future<UpgraderVersionInfo?> updateVersionInfo() async {
    if (_packageInfo == null || _packageInfo!.packageName.isEmpty) {
      return null;
    }

    // Determine the store to be used for this app.
    final store = storeController.getUpgraderStore(upgraderOS);
    if (store == null) return null;

    // Determine the installed version of this app.
    late Version installedVersion;
    try {
      installedVersion = Version.parse(_installedVersion!);
    } catch (e) {
      if (debugLogging) {
        print('upgrader: installedVersion exception: $e');
        return null;
      }
    }

    // Determine the country code of the locale, defaulting to `US`.
    final country = countryCode ?? findCountryCode();
    if (debugLogging) {
      print('upgrader: countryCode: $country');
    }

    // Determine the language code of the locale, defaulting to `en`.
    final language = languageCode ?? findLanguageCode();
    if (debugLogging) {
      print('upgrader: languageCode: $language');
    }

    // Get the version info from the store.
    final versionInfo = store.getVersionInfo(
        upgrader: this,
        installedVersion: installedVersion,
        country: country,
        language: language);

    return versionInfo;
  }

  /// Android info is fetched by parsing the html of the app store page.
  Future<bool?> getAndroidStoreVersion(
      {String? country, String? language}) async {
    return true;
  }

  bool isAppcastThisPlatform() {
    if (appcastConfig == null ||
        appcastConfig!.url == null ||
        appcastConfig!.url!.isEmpty) {
      return false;
    }

    // Since this appcast config contains a URL, this appcast is valid.
    // However, if the supported OS is not listed, it is not supported.
    // When there are no supported OSes listed, they are all supported.
    var supported = true;
    if (appcastConfig!.supportedOS != null) {
      supported =
          appcastConfig!.supportedOS!.contains(upgraderOS.operatingSystem);
    }
    return supported;
  }

  bool verifyInit() {
    if (!_initCalled) {
      throw ('upgrader: initialize() not called. Must be called first.');
    }
    return true;
  }

  String appName() {
    verifyInit();
    return _packageInfo?.appName ?? '';
  }

  String body(UpgraderMessages messages) {
    var msg = messages.message(UpgraderMessage.body)!;
    msg = msg.replaceAll('{{appName}}', appName());
    msg = msg.replaceAll(
        '{{currentAppStoreVersion}}', currentAppStoreVersion ?? '');
    msg = msg.replaceAll(
        '{{currentInstalledVersion}}', currentInstalledVersion ?? '');
    return msg;
  }

  /// Determine which [UpgraderMessages] object to use. It will be either the one passed
  /// to [Upgrader], or one based on the app locale.
  UpgraderMessages determineMessages(BuildContext context) {
    {
      late UpgraderMessages appMessages;
      if (messages != null) {
        appMessages = messages!;
      } else {
        String? languageCode;
        try {
          // Get the current locale in the app.
          final locale = Localizations.localeOf(context);
          // Get the current language code in the app.
          languageCode = locale.languageCode;
          if (debugLogging) {
            print('upgrader: current locale: $locale');
          }
        } catch (e) {
          // ignored, really.
        }

        appMessages = UpgraderMessages(code: languageCode);
      }

      if (appMessages.languageCode.isEmpty) {
        print('upgrader: error -> languageCode is empty');
      } else if (debugLogging) {
        print('upgrader: languageCode: ${appMessages.languageCode}');
      }

      return appMessages;
    }
  }

  bool blocked() {
    return belowMinAppVersion() || versionInfo?.isCriticalUpdate == true;
  }

  bool shouldDisplayUpgrade() {
    final isBlocked = blocked();

    if (debugLogging) {
      print('upgrader: blocked: $isBlocked');
      print('upgrader: debugDisplayAlways: $debugDisplayAlways');
      print('upgrader: debugDisplayOnce: $debugDisplayOnce');
      print('upgrader: hasAlerted: $_hasAlerted');
    }

    bool rv = true;
    if (debugDisplayAlways || (debugDisplayOnce && !_hasAlerted)) {
      rv = true;
    } else if (!isUpdateAvailable()) {
      rv = false;
    } else if (isBlocked) {
      rv = true;
    } else if (isTooSoon() || alreadyIgnoredThisVersion()) {
      rv = false;
    }
    if (debugLogging) {
      print('upgrader: shouldDisplayUpgrade: $rv');
    }

    // Call the [willDisplayUpgrade] callback when available.
    if (willDisplayUpgrade != null && versionInfo != null) {
      willDisplayUpgrade!(
        display: rv,
        installedVersion: _installedVersion,
        versionInfo: versionInfo!,
      );
    }

    return rv;
  }

  /// Is installed version below minimum app version?
  bool belowMinAppVersion() {
    var rv = false;
    if (minAppVersion != null) {
      try {
        final minVersion = Version.parse(minAppVersion!);
        final installedVersion = Version.parse(_installedVersion!);
        rv = installedVersion < minVersion;
      } catch (e) {
        if (debugLogging) {
          print(e);
        }
      }
    }
    return rv;
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted!);
    final rv = lastAlertedDuration < durationUntilAlertAgain;
    if (rv && debugLogging) {
      print('upgrader: isTooSoon: true');
    }
    return rv;
  }

  bool alreadyIgnoredThisVersion() {
    final rv = _userIgnoredVersion != null &&
        _userIgnoredVersion == versionInfo?.appStoreVersion;
    if (rv && debugLogging) {
      print('upgrader: alreadyIgnoredThisVersion: true');
    }
    return rv;
  }

  bool isUpdateAvailable() {
    if (debugLogging) {
      print('upgrader: installedVersion: $_installedVersion');
      print('upgrader: minAppVersion: $minAppVersion');
    }
    if (versionInfo?.appStoreVersion == null || _installedVersion == null) {
      if (debugLogging) print('upgrader: isUpdateAvailable: false');
      return false;
    }

    try {
      final installedVersion = Version.parse(_installedVersion!);

      final available = versionInfo!.appStoreVersion! > installedVersion;
      _updateAvailable = available ? versionInfo?.appStoreVersion : null;
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader: isUpdateAvailable: $e');
      }
    }
    final isAvailable = _updateAvailable != null;
    if (debugLogging) print('upgrader: isUpdateAvailable: $isAvailable');
    return isAvailable;
  }

  /// Determine the current country code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `US`.
  String? findCountryCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null || locale.countryCode == null
        ? 'US'
        : locale.countryCode;
    return code;
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `en`.
  String? findLanguageCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null ? 'en' : locale.languageCode;
    return code;
  }

  static Future<void> clearSavedSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('userIgnoredVersion');
    await prefs.remove('lastTimeAlerted');
    await prefs.remove('lastVersionAlerted');

    return;
  }

  Future<bool> saveIgnored() async {
    var prefs = await SharedPreferences.getInstance();

    _userIgnoredVersion = versionInfo?.appStoreVersion;
    await prefs.setString(
        'userIgnoredVersion', _userIgnoredVersion?.toString() ?? '');
    return true;
  }

  Future<bool> saveLastAlerted() async {
    var prefs = await SharedPreferences.getInstance();
    _lastTimeAlerted = DateTime.now();
    await prefs.setString('lastTimeAlerted', _lastTimeAlerted.toString());

    _lastVersionAlerted = versionInfo?.appStoreVersion;
    await prefs.setString(
        'lastVersionAlerted', _lastVersionAlerted?.toString() ?? '');

    _hasAlerted = true;
    return true;
  }

  Future<bool> getSavedPrefs() async {
    var prefs = await SharedPreferences.getInstance();
    final lastTimeAlerted = prefs.getString('lastTimeAlerted');
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    final versionAlerted = prefs.getString('lastVersionAlerted');
    if (versionAlerted != null) {
      try {
        _lastVersionAlerted = Version.parse(versionAlerted);
      } catch (e) {
        if (debugLogging) {
          print('upgrader: lastVersionAlerted exception: $e');
        }
      }
    }
    final ignoredVersion = prefs.getString('userIgnoredVersion');
    if (ignoredVersion != null) {
      try {
        _userIgnoredVersion = Version.parse(ignoredVersion);
      } catch (e) {
        if (debugLogging) {
          print('upgrader: userIgnoredVersion exception: $e');
        }
      }
    }

    return true;
  }

  void sendUserToAppStore() async {
    final appStoreListingURL = versionInfo?.appStoreListingURL;
    if (appStoreListingURL == null || appStoreListingURL.isEmpty) {
      if (debugLogging) {
        print('upgrader: empty appStoreListingURL');
      }
      return;
    }

    if (debugLogging) {
      print('upgrader: launching: $appStoreListingURL');
    }

    if (await canLaunchUrl(Uri.parse(appStoreListingURL))) {
      try {
        await launchUrl(Uri.parse(appStoreListingURL),
            mode: upgraderOS.isAndroid
                ? LaunchMode.externalNonBrowserApplication
                : LaunchMode.platformDefault);
      } catch (e) {
        if (debugLogging) {
          print('upgrader: launch to app store failed: $e');
        }
      }
    } else {}
  }
}

class UpgraderVersionInfo {
  final String? appStoreListingURL;
  final Version? appStoreVersion;
  final Version? installedVersion;
  final bool? isCriticalUpdate;
  final Version? minAppVersion;
  final String? releaseNotes;

  UpgraderVersionInfo({
    this.appStoreListingURL,
    this.appStoreVersion,
    this.installedVersion,
    this.isCriticalUpdate,
    this.minAppVersion,
    this.releaseNotes,
  });

  @override
  String toString() {
    return 'appStoreListingURL: $appStoreListingURL, '
        'appStoreVersion: $appStoreVersion, '
        'installedVersion: $installedVersion, '
        'isCriticalUpdate: $isCriticalUpdate, '
        'minAppVersion: $minAppVersion, '
        'releaseNotes: $releaseNotes';
  }
}

abstract class UpgraderStore {
  Future<UpgraderVersionInfo> getVersionInfo(
      {required Upgrader upgrader,
      required Version installedVersion,
      required String? country,
      required String? language});
}

class UpgraderAppStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required Upgrader upgrader,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    String? appStoreListingURL;
    Version? appStoreVersion;
    bool? isCriticalUpdate;
    Version? minAppVersion;
    String? releaseNotes;

    final iTunes = ITunesSearchAPI();
    iTunes.debugLogging = upgrader.debugLogging;
    iTunes.client = upgrader.client;
    final response = await (iTunes
        .lookupByBundleId(upgrader.packageInfo!.packageName, country: country));

    if (response != null) {
      final version = iTunes.version(response);
      if (version != null) {
        try {
          appStoreVersion = Version.parse(version);
        } catch (e) {
          if (upgrader.debugLogging) {
            print('upgrader: UpgraderAppStore.appStoreVersion exception: $e');
          }
        }
      }
      appStoreListingURL = iTunes.trackViewUrl(response);
      releaseNotes ??= iTunes.releaseNotes(response);
      minAppVersion = iTunes.minAppVersion(response);
      if (minAppVersion != null) {
        if (upgrader.debugLogging) {
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
    if (upgrader.debugLogging) {
      print('upgrader: UpgraderAppStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

class UpgraderPlayStore extends UpgraderStore {
  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required Upgrader upgrader,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    final id = upgrader.packageInfo!.packageName;
    final playStore = PlayStoreSearchAPI(client: upgrader.client);
    playStore.debugLogging = upgrader.debugLogging;

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
          if (upgrader.debugLogging) {
            print('upgrader: UpgraderPlayStore.appStoreVersion exception: $e');
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

          if (upgrader.debugLogging) {
            print('upgrader: UpgraderPlayStore.minAppVersion: $minAppVersion');
          }
        } catch (e) {
          if (upgrader.debugLogging) {
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
    if (upgrader.debugLogging) {
      print('upgrader: UpgraderPlayStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

class UpgraderAppcastStore extends UpgraderStore {
  UpgraderAppcastStore({required this.appcastURL});

  final String appcastURL;

  @override
  Future<UpgraderVersionInfo> getVersionInfo(
      {required Upgrader upgrader,
      required Version installedVersion,
      required String? country,
      required String? language}) async {
    String? appStoreListingURL;
    Version? appStoreVersion;
    bool? isCriticalUpdate;
    String? releaseNotes;

    final appcast = Appcast(client: upgrader.client);
    await appcast.parseAppcastItemsFromUri(appcastURL);
    if (upgrader.debugLogging) {
      var count = appcast.items == null ? 0 : appcast.items!.length;
      print('upgrader: UpgraderAppcastStore item count: $count');
    }
    final criticalUpdateItem = appcast.bestCriticalItem();
    final criticalVersion = criticalUpdateItem?.versionString ?? '';

    final bestItem = appcast.bestItem();
    if (bestItem != null &&
        bestItem.versionString != null &&
        bestItem.versionString!.isNotEmpty) {
      if (upgrader.debugLogging) {
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
        if (upgrader.debugLogging) {
          print(
              'upgrader: UpgraderAppcastStore: updateVersionInfo could not parse version info $e');
        }
      }

      if (bestItem.versionString != null) {
        try {
          appStoreVersion = Version.parse(bestItem.versionString!);
        } catch (e) {
          if (upgrader.debugLogging) {
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
    if (upgrader.debugLogging) {
      print('upgrader: UpgraderAppcastStore: version info: $versionInfo');
    }
    return versionInfo;
  }
}

class UpgraderConfiguration {
  String get appStoreListingURL => throw UnimplementedError();
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
