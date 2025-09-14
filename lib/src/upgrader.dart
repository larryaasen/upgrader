// Copyright (c) 2018-2025 Larry Aasen. All rights reserved.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
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
/// installedVersion, and versionInfo.
typedef WillDisplayUpgradeCallback = void Function({
  required bool display,
  String? installedVersion,
  UpgraderVersionInfo? versionInfo,
});

/// Creates a shared instance of [Upgrader].
Upgrader _sharedInstance = Upgrader();

/// An upgrade controller that maintains a [state] that is used to
/// trigger an alert or other UI to evaluate upgrading criteria.
///
/// See also:
///
///  * [UpgraderMessages], the default localized messages used for display.
///  * [UpgraderState], the [Upgrader] state.
class Upgrader with WidgetsBindingObserver {
  /// Creates an uprade controller that maintains a [state] that is used to
  /// trigger an alert or other UI to evaluate upgrading criteria.
  Upgrader({
    http.Client? client,
    Map<String, String>? clientHeaders,
    String? countryCode,
    bool debugDisplayAlways = false,
    bool debugDisplayOnce = false,
    bool debugLogging = false,
    Duration durationUntilAlertAgain = const Duration(days: 3),
    String? languageCode,
    UpgraderMessages? messages,
    String? minAppVersion,
    UpgraderStoreController? storeController,
    UpgraderOS? upgraderOS,
    this.willDisplayUpgrade,
  })  : _state = UpgraderState(
          client: client ?? http.Client(),
          clientHeaders: clientHeaders,
          countryCodeOverride: countryCode,
          debugDisplayAlways: debugDisplayAlways,
          debugDisplayOnce: debugDisplayOnce,
          debugLogging: debugLogging,
          durationUntilAlertAgain: durationUntilAlertAgain,
          languageCodeOverride: languageCode,
          messages: messages,
          minAppVersion:
              parseVersion(minAppVersion, 'minAppVersion', debugLogging),
          upgraderOS: upgraderOS ?? UpgraderOS(),
        ),
        storeController = storeController ?? UpgraderStoreController() {
    if (_state.debugLogging) {
      print("upgrader: instantiated");
    }
  }

  /// The controller that provides the store details for each platform.
  UpgraderStoreController storeController;

  /// Called when [Upgrader] determines that an upgrade may or may not be
  /// displayed. The [value] parameter will be true when it should be displayed,
  /// and false when it should not be displayed. One good use for this callback
  /// is logging metrics for your app.
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  /// A shared instance of [Upgrader].
  static Upgrader get sharedInstance => _sharedInstance;

  /// The [Upgrader] state.
  UpgraderState _state;
  UpgraderState get state => _state;

  /// A stream that provides a new state each time an evaluation should be performed.
  /// The values will always be the state.
  Stream<UpgraderState> get stateStream => _streamController.stream;
  final _streamController = StreamController<UpgraderState>.broadcast();

  /// Track the initialization future so that [initialize] can be called multiple times.
  Future<bool>? _futureInit;

  bool _initCalled = false;
  Version? _updateAvailable;
  DateTime? _lastTimeAlerted;
  Version? _lastVersionAlerted;
  Version? _userIgnoredVersion;
  bool _hasAlerted = false;

  static const notInitializedExceptionMessage =
      'upgrader: initialize() not called. Must be called first.';

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

      if (state.debugLogging) print('upgrader: ${state.upgraderOS}');

      if (state.packageInfo == null) {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          updateState(state.copyWith(packageInfo: packageInfo));
        } catch (e) {
          if (state.debugLogging) {
            print('upgrader: PackageInfo exception: $e');
          }
        }
      }

      final packageInfo = state.packageInfo;
      if (state.debugLogging && packageInfo != null) {
        print('upgrader: packageInfo packageName: ${packageInfo.packageName}');
        print('upgrader: packageInfo appName: ${packageInfo.appName}');
        print('upgrader: packageInfo version: ${packageInfo.version}');
      }

      await updateVersionInfo();

      // Add an observer of application events, so that when the app returns
      // from the background, the version info is updated.
      WidgetsBinding.instance.addObserver(this);

      return true;
    });
    return _futureInit!;
  }

  /// Updates the Upgrader state, which updates the stream, which triggers a
  /// call to [shouldDisplayUpgrade].
  void updateState(UpgraderState newState,
      {bool updateTheVersionInfo = false}) {
    _state = newState;

    if (updateTheVersionInfo) {
      Future.delayed(Duration.zero).then((value) async {
        await updateVersionInfo();
      });
      return;
    }
    updateStream();
  }

  /// Updates the stream with the current state, which triggers the stream to
  /// indicate an evaluation should be performed.
  void updateStream() {
    _streamController.add(_state);
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
    }
  }

  /// Update the version info for this app by using an [UpgraderStore] to get
  /// the [UpgraderVersionInfo].
  Future<UpgraderVersionInfo?> updateVersionInfo() async {
    if (state.packageInfo == null || state.packageInfo!.packageName.isEmpty) {
      updateState(state.copyWithNull(versionInfo: null));
      return null;
    }

    // Determine the store to be used for this app.
    final store = storeController.getUpgraderStore(state.upgraderOS);
    if (store == null) {
      if (state.debugLogging) {
        print('upgrader: updateVersionInfo found no store controller');
      }
      updateState(state.copyWithNull(versionInfo: null));
      return null;
    }

    // Determine the installed version of this app.
    late Version installedVersion;
    try {
      installedVersion = Version.parse(state.packageInfo!.version);
    } catch (e) {
      if (state.debugLogging) {
        print('upgrader: installedVersion exception: $e');
      }
      updateState(state.copyWithNull(versionInfo: null));
      return null;
    }

    final locale = findLocale();

    // Determine the country code of the locale, defaulting to `US`.
    final country =
        state.countryCodeOverride ?? findCountryCode(locale: locale);
    if (state.debugLogging) {
      print('upgrader: countryCode: $country');
    }

    // Determine the language code of the locale, defaulting to `en`.
    final language =
        state.languageCodeOverride ?? findLanguageCode(locale: locale);
    if (state.debugLogging) {
      print('upgrader: languageCode: $language');
    }

    // Get the version info from the store.
    final versionInfo = await store.getVersionInfo(
        state: state,
        installedVersion: installedVersion,
        country: country,
        language: language);

    updateState(state.copyWith(versionInfo: versionInfo));

    return versionInfo;
  }

  bool verifyInit() {
    if (!_initCalled) {
      throw (notInitializedExceptionMessage);
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

  bool blocked() {
    return belowMinAppVersion() || versionInfo?.isCriticalUpdate == true;
  }

  bool shouldDisplayUpgrade() {
    final isBlocked = blocked();

    if (state.debugLogging) {
      print('upgrader: blocked: $isBlocked');
      print('upgrader: debugDisplayAlways: ${state.debugDisplayAlways}');
      print('upgrader: debugDisplayOnce: ${state.debugDisplayOnce}');
      print('upgrader: hasAlerted: $_hasAlerted');
    }

    bool rv = true;
    if (state.debugDisplayAlways || (state.debugDisplayOnce && !_hasAlerted)) {
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
    if (willDisplayUpgrade != null) {
      willDisplayUpgrade!(
        display: rv,
        installedVersion: state.packageInfo?.version,
        versionInfo: versionInfo,
      );
    }

    return rv;
  }

  /// Is installed version below minimum app version?
  bool belowMinAppVersion() {
    var rv = false;
    final minVersion = state.minAppVersion ?? versionInfo?.minAppVersion;
    if (minVersion != null && state.packageInfo != null) {
      try {
        final installedVersion = Version.parse(state.packageInfo!.version);
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
    final rv = lastAlertedDuration < state.durationUntilAlertAgain;
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
      print('upgrader: installedVersion: ${state.packageInfo?.version}');
      print('upgrader: minAppVersion: ${state.minAppVersion}');
    }
    if (versionInfo?.appStoreVersion == null ||
        state.packageInfo?.version == null) {
      if (state.debugLogging) print('upgrader: isUpdateAvailable: false');
      return false;
    }

    try {
      final installedVersion = Version.parse(state.packageInfo!.version);

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

  Locale findLocale({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    }
    locale ??= PlatformDispatcher.instance.locale;
    if (state.debugLogging) {
      print('upgrader: current locale: $locale');
    }
    return locale;
  }

  /// Determine the current country code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `US`.
  String? findCountryCode({required Locale locale}) {
    final code = locale.countryCode ?? 'US';
    return code;
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `en`.
  String? findLanguageCode({required Locale locale}) {
    final code = locale.languageCode;
    return code;
  }

  static Future<void> clearSavedSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('userIgnoredVersion');
    await prefs.remove('lastTimeAlerted');
    await prefs.remove('lastVersionAlerted');

    return;
  }

  /// Determine which [UpgraderMessages] object to use. It will be either the one passed
  /// to [Upgrader], or one based on the app locale.
  UpgraderMessages determineMessages(BuildContext context) {
    if (state.messages != null) return state.messages!;

    String? languageCode = state.languageCodeOverride;
    if (languageCode == null) {
      final locale = findLocale(context: context);
      languageCode = locale.languageCode;
    }

    final appMessages = UpgraderMessages(code: languageCode);

    if (appMessages.languageCode.isEmpty) {
      print('upgrader: error -> languageCode is empty');
    } else if (state.debugLogging) {
      print('upgrader: languageCode: ${appMessages.languageCode}');
    }

    return appMessages;
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

  /// Launch the app store from the app store listing URL.
  Future<void> sendUserToAppStore() async {
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
            mode: state.upgraderOS.isAndroid
                ? LaunchMode.externalNonBrowserApplication
                : LaunchMode.platformDefault);
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: launch to app store failed: $e');
        }
      }
    }
  }

  static Version? parseVersion(
      String? version, String name, bool debugLogging) {
    if (version == null) return null;
    try {
      return Version.parse(version);
    } catch (e) {
      // if (state.debugLogging) {
      print('upgrader: _parseVersion $name exception: $e');
      // }
      return null;
    }
  }
}

extension UpgraderExt on Upgrader {
  String? get currentAppStoreListingURL =>
      state.versionInfo?.appStoreListingURL;

  String? get currentAppStoreVersion =>
      state.versionInfo?.appStoreVersion?.toString();

  String? get currentInstalledVersion => state.packageInfo?.version;

  String? get releaseNotes => state.versionInfo?.releaseNotes;

  void installPackageInfo({PackageInfo? packageInfo}) {
    updateState(state.copyWith(packageInfo: packageInfo),
        updateTheVersionInfo: true);
  }

  /// The minAppVersion in the Upgrader state.
  String? get minAppVersion => state.minAppVersion.toString();

  set minAppVersion(String? version) {
    if (version == null) {
      updateState(
          state.copyWithNull(
            minAppVersion: true,
          ),
          updateTheVersionInfo: true);
    } else {
      final parsedVersion =
          Upgrader.parseVersion(version, 'minAppVersion', state.debugLogging);
      if (parsedVersion != null) {
        updateState(state.copyWith(minAppVersion: parsedVersion),
            updateTheVersionInfo: true);
      }
    }
  }

  /// The latest version info for this app.
  UpgraderVersionInfo? get versionInfo => state.versionInfo;
}
