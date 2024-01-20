// Copyright (c) 2018-2024 Larry Aasen. All rights reserved.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'upgrade_messages.dart';
import 'upgrade_os.dart';
import 'upgrade_state.dart';
import 'upgrade_store_controller.dart';
import 'upgrader_version_info.dart';

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

/// Creates a shared instance of [Upgrader].
Upgrader _sharedInstance = Upgrader();

/// A class to configure the upgrade dialog.
class Upgrader with WidgetsBindingObserver {
  Upgrader({
    this.messages,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    bool debugLogging = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
    this.willDisplayUpgrade,
    http.Client? client,
    this.countryCode,
    this.languageCode,
    this.minAppVersion,
    UpgraderStoreController? storeController,
    UpgraderOS? upgraderOS,
  })  : _state = UpgraderState(
            client: client ?? http.Client(), debugLogging: debugLogging),
        storeController = storeController ?? UpgraderStoreController(),
        upgraderOS = upgraderOS ?? UpgraderOS() {
    if (debugLogging) print("upgrader: instantiated");
  }

  /// The [Upgrader] state.
  UpgraderState _state;
  UpgraderState get state => _state;

  /// The controller that provides the store details for each platform.
  final UpgraderStoreController storeController;

  /// The country code that will override the system locale. Optional.
  final String? countryCode;

  /// The country code that will override the system locale. Optional. Used only for Android.
  final String? languageCode;

  /// For debugging, always force the upgrade to be available.
  bool debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  bool debugDisplayOnce;

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
  String? _installedVersion;
  Version? _updateAvailable;
  DateTime? _lastTimeAlerted;
  Version? _lastVersionAlerted;
  Version? _userIgnoredVersion;
  bool _hasAlerted = false;

  /// Track the initialization future so that [initialize] can be called multiple times.
  Future<bool>? _futureInit;

  /// A stream that provides a new state each time an evaluation should be performed.
  /// The values will always be the state.
  Stream<UpgraderState> get stateStream => _streamController.stream;
  final _streamController = StreamController<UpgraderState>.broadcast();

  /// A shared instance of [Upgrader].
  static Upgrader get sharedInstance => _sharedInstance;

  static const notInitializedExceptionMessage =
      'upgrader: initialize() not called. Must be called first.';

  String? get currentAppStoreListingURL =>
      state.versionInfo?.appStoreListingURL;

  String? get currentAppStoreVersion =>
      state.versionInfo?.appStoreVersion?.toString();

  String? get currentInstalledVersion => _installedVersion;

  String? get releaseNotes => state.versionInfo?.releaseNotes;

  void installPackageInfo({PackageInfo? packageInfo}) {
    updateState(state.copyWith(packageInfo: packageInfo));
    _initCalled = false;
  }

  // void installAppStoreVersion(String version) => _appStoreVersion = version;

  // void installAppStoreListingURL(String url) => _appStoreListingURL = url;

  /// The latest version info for this app.
  UpgraderVersionInfo? get versionInfo => state.versionInfo;

  /// Initialize [Upgrader] by getting saved preferences, getting platform package info, and getting
  /// released version info.
  Future<bool> initialize() async {
    if (state.debugLogging) print('upgrader: initialize called');

    if (_futureInit != null) return _futureInit!;

    _futureInit = Future(() async {
      if (state.debugLogging) print('upgrader: initializing');

      if (_initCalled) {
        assert(false, 'This should never happen.');
        return true;
      }
      _initCalled = true;

      await getSavedPrefs();

      if (state.debugLogging) print('upgrader: $upgraderOS');

      if (state.packageInfo == null) {
        updateState(
            state.copyWith(packageInfo: await PackageInfo.fromPlatform()));
        if (state.debugLogging) {
          print(
              'upgrader: package info packageName: ${state.packageInfo!.packageName}');
          print(
              'upgrader: package info appName: ${state.packageInfo!.appName}');
          print(
              'upgrader: package info version: ${state.packageInfo!.version}');
        }
      }

      _installedVersion = state.packageInfo!.version;

      updateState(state.copyWith(versionInfo: await updateVersionInfo()));

      // Add an observer of application events, so that when the app returns
      // from the background, the version info is updated.
      WidgetsBinding.instance.addObserver(this);

      /// Trigger the stream to indicate an evaluation should be performed.
      /// The value will always be the state.
      _streamController.add(state);

      return true;
    });
    return _futureInit!;
  }

  /// Update the Upgrader state.
  void updateState(UpgraderState newState) {
    _state = newState;
  }

  /// Remove any resources allocated.
  void dispose() {
    // Remove the observer of application events.
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Handle application events.
  @override
  Future<void> didChangeAppLifecycleState(
      AppLifecycleState lifecycleState) async {
    super.didChangeAppLifecycleState(lifecycleState);

    // When app has resumed from background.
    if (lifecycleState == AppLifecycleState.resumed) {
      await updateVersionInfo();

      /// Trigger the stream to indicate another evaluation should be performed.
      /// The value will always be the state.
      _streamController.add(state);
    }
  }

  /// Update the version info for this app.
  Future<UpgraderVersionInfo?> updateVersionInfo() async {
    if (state.packageInfo == null || state.packageInfo!.packageName.isEmpty) {
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
      if (state.debugLogging) {
        print('upgrader: installedVersion exception: $e');
        return null;
      }
    }

    // Determine the country code of the locale, defaulting to `US`.
    final country = countryCode ?? findCountryCode();
    if (state.debugLogging) {
      print('upgrader: countryCode: $country');
    }

    // Determine the language code of the locale, defaulting to `en`.
    final language = languageCode ?? findLanguageCode();
    if (state.debugLogging) {
      print('upgrader: languageCode: $language');
    }

    // Get the version info from the store.
    final versionInfo = store.getVersionInfo(
        state: state,
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

  bool verifyInit() {
    if (!_initCalled) {
      throw ('upgrader: initialize() not called. Must be called first.');
    }
    return true;
  }

  String appName() {
    verifyInit();
    return state.packageInfo?.appName ?? '';
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
          if (state.debugLogging) {
            print('upgrader: current locale: $locale');
          }
        } catch (e) {
          // ignored, really.
        }

        appMessages = UpgraderMessages(code: languageCode);
      }

      if (appMessages.languageCode.isEmpty) {
        print('upgrader: error -> languageCode is empty');
      } else if (state.debugLogging) {
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

    if (state.debugLogging) {
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
    if (state.debugLogging) {
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
        if (state.debugLogging) {
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
    if (rv && state.debugLogging) {
      print('upgrader: isTooSoon: true');
    }
    return rv;
  }

  bool alreadyIgnoredThisVersion() {
    final rv = _userIgnoredVersion != null &&
        _userIgnoredVersion == versionInfo?.appStoreVersion;
    if (rv && state.debugLogging) {
      print('upgrader: alreadyIgnoredThisVersion: true');
    }
    return rv;
  }

  bool isUpdateAvailable() {
    if (state.debugLogging) {
      print('upgrader: installedVersion: $_installedVersion');
      print('upgrader: minAppVersion: $minAppVersion');
    }
    if (versionInfo?.appStoreVersion == null || _installedVersion == null) {
      if (state.debugLogging) print('upgrader: isUpdateAvailable: false');
      return false;
    }

    try {
      final installedVersion = Version.parse(_installedVersion!);

      final available = versionInfo!.appStoreVersion! > installedVersion;
      _updateAvailable = available ? versionInfo?.appStoreVersion : null;
    } on Exception catch (e) {
      if (state.debugLogging) {
        print('upgrader: isUpdateAvailable: $e');
      }
    }
    final isAvailable = _updateAvailable != null;
    if (state.debugLogging) print('upgrader: isUpdateAvailable: $isAvailable');
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
        if (state.debugLogging) {
          print('upgrader: lastVersionAlerted exception: $e');
        }
      }
    }
    final ignoredVersion = prefs.getString('userIgnoredVersion');
    if (ignoredVersion != null) {
      try {
        _userIgnoredVersion = Version.parse(ignoredVersion);
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: userIgnoredVersion exception: $e');
        }
      }
    }

    return true;
  }

  void sendUserToAppStore() async {
    final appStoreListingURL = versionInfo?.appStoreListingURL;
    if (appStoreListingURL == null || appStoreListingURL.isEmpty) {
      if (state.debugLogging) {
        print('upgrader: empty appStoreListingURL');
      }
      return;
    }

    if (state.debugLogging) {
      print('upgrader: launching: $appStoreListingURL');
    }

    if (await canLaunchUrl(Uri.parse(appStoreListingURL))) {
      try {
        await launchUrl(Uri.parse(appStoreListingURL),
            mode: upgraderOS.isAndroid
                ? LaunchMode.externalNonBrowserApplication
                : LaunchMode.platformDefault);
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: launch to app store failed: $e');
        }
      }
    } else {}
  }
}
