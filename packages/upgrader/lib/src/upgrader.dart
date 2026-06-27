import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader_core/upgrader_core.dart' as core;
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'upgrade_messages.dart';
import 'upgrade_os.dart';
import 'upgrade_state.dart';

typedef BoolCallback = bool Function();
typedef VoidBoolCallback = void Function(bool value);
typedef WillDisplayUpgradeCallback = core.WillDisplayUpgradeCallback;

Upgrader _sharedInstance = Upgrader();

class Upgrader with WidgetsBindingObserver {
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
    bool showOnlyMandatoryUpdates = false,
    core.UpgraderStoreController? storeController,
    UpgraderOS? upgraderOS,
    WillDisplayUpgradeCallback? willDisplayUpgrade,
    core.UpgraderAppInfoProvider? appInfoProvider,
    core.UpgraderPreferencesStore? preferencesStore,
    core.UpgraderStoreLauncher? storeLauncher,
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
              core.UpgraderEngine.parseVersion(minAppVersion, 'minAppVersion', debugLogging),
          showOnlyMandatoryUpdates: showOnlyMandatoryUpdates,
          upgraderOS: upgraderOS ?? UpgraderOS(),
        ),
        _appInfoProvider = appInfoProvider ?? const _PackageInfoAppInfoProvider(),
        _preferencesStore = preferencesStore,
        _storeLauncher = storeLauncher,
        _coreEngine = core.UpgraderEngine(
          state: UpgraderState(
            client: client ?? http.Client(),
            clientHeaders: clientHeaders,
            countryCodeOverride: countryCode,
            debugDisplayAlways: debugDisplayAlways,
            debugDisplayOnce: debugDisplayOnce,
            debugLogging: debugLogging,
            durationUntilAlertAgain: durationUntilAlertAgain,
            languageCodeOverride: languageCode,
            minAppVersion:
                core.UpgraderEngine.parseVersion(minAppVersion, 'minAppVersion', debugLogging),
            showOnlyMandatoryUpdates: showOnlyMandatoryUpdates,
            upgraderOS: upgraderOS ?? UpgraderOS(),
          ).toCoreState(),
          storeController: storeController,
          willDisplayUpgrade: willDisplayUpgrade,
        ) {
    if (_state.debugLogging) {
      print('upgrader: instantiated');
    }
  }

  static const notInitializedExceptionMessage =
      'upgrader: initialize() not called. Must be called first.';

  final core.UpgraderAppInfoProvider _appInfoProvider;
  final core.UpgraderPreferencesStore? _preferencesStore;
  final core.UpgraderStoreLauncher? _storeLauncher;
  final core.UpgraderEngine _coreEngine;
  final _streamController = StreamController<UpgraderState>.broadcast();

  UpgraderState _state;
  UpgraderState get state => _state;
  Stream<UpgraderState> get stateStream => _streamController.stream;

  core.UpgraderStoreController get storeController => _coreEngine.storeController;
  set storeController(core.UpgraderStoreController value) {
    _coreEngine.storeController = value;
  }

  WillDisplayUpgradeCallback? get willDisplayUpgrade => _coreEngine.willDisplayUpgrade;
  set willDisplayUpgrade(WillDisplayUpgradeCallback? value) {
    _coreEngine.willDisplayUpgrade = value;
  }

  static Upgrader get sharedInstance => _sharedInstance;

  Future<bool>? _futureInit;
  bool _initCalled = false;

  core.UpgraderPreferencesStore get _effectivePreferencesStore =>
      _preferencesStore ?? _SharedPreferencesStore.instance;

  core.UpgraderStoreLauncher get _effectiveStoreLauncher =>
      _storeLauncher ?? const _UrlLauncherStoreLauncher();

  Future<bool> initialize() async {
    if (state.debugLogging) {
      print('upgrader: initialize called');
    }

    if (_futureInit != null) {
      return _futureInit!;
    }

    _futureInit = Future(() async {
      if (state.debugLogging) {
        print('upgrader: initializing');
      }

      if (_initCalled) {
        return true;
      }
      _initCalled = true;

      await getSavedPrefs();

      if (state.debugLogging) {
        print('upgrader: ${state.upgraderOS}');
      }

      if (state.packageInfo == null) {
        try {
          final packageInfo = await _appInfoProvider.getPackageInfo();
          if (packageInfo != null) {
            updateState(_state.copyWith(packageInfo: _toPackageInfo(packageInfo)));
          }
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
      WidgetsBinding.instance.addObserver(this);
      _coreEngine.markInitialized();
      return true;
    });

    return _futureInit!;
  }

  void updateState(UpgraderState newState, {bool updateTheVersionInfo = false}) {
    _state = newState;
    _coreEngine.updateState(_state.toCoreState());
    if (updateTheVersionInfo) {
      Future.delayed(Duration.zero).then((_) => updateVersionInfo());
      return;
    }
    updateStream();
  }

  void updateStream() {
    _streamController.add(_state);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState lifecycleState) async {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.resumed) {
      await updateVersionInfo();
    }
  }

  Future<core.UpgraderVersionInfo?> updateVersionInfo() async {
    final locale = findLocale();
    final versionInfo = await _coreEngine.updateVersionInfo(
      countryCode: findCountryCode(locale: locale),
      languageCode: findLanguageCode(locale: locale),
    );
    if (versionInfo == null) {
      updateState(_state.copyWithNull(versionInfo: true));
      return null;
    }
    updateState(_state.copyWith(versionInfo: versionInfo));
    return versionInfo;
  }

  bool verifyInit() {
    if (!_coreEngine.initialized) {
      throw (notInitializedExceptionMessage);
    }
    return true;
  }

  String appName() {
    verifyInit();
    return _coreEngine.appName();
  }

  String body(UpgraderMessages messages) {
    var message = messages.message(UpgraderMessage.body)!;
    message = message.replaceAll('{{appName}}', appName());
    message = message.replaceAll('{{currentAppStoreVersion}}', currentAppStoreVersion ?? '');
    message = message.replaceAll('{{currentInstalledVersion}}', currentInstalledVersion ?? '');
    return message;
  }

  bool blocked() => _coreEngine.blocked();
  bool shouldDisplayUpgrade() => _coreEngine.shouldDisplayUpgrade();
  bool belowMinAppVersion() => _coreEngine.belowMinAppVersion();
  bool isTooSoon() => _coreEngine.isTooSoon();
  bool alreadyIgnoredThisVersion() => _coreEngine.alreadyIgnoredThisVersion();
  bool isUpdateAvailable() => _coreEngine.isUpdateAvailable();

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

  String? findCountryCode({required Locale locale}) => locale.countryCode ?? 'US';
  String? findLanguageCode({required Locale locale}) => locale.languageCode;

  static Future<void> clearSavedSettings() async {
    await core.UpgraderEngine.clearSavedSettings(_SharedPreferencesStore.instance);
  }

  UpgraderMessages determineMessages(BuildContext context) {
    if (state.messages != null) {
      return state.messages!;
    }

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

  Future<bool> saveIgnored() => _coreEngine.saveIgnored(_effectivePreferencesStore);
  Future<bool> saveLastAlerted() => _coreEngine.saveLastAlerted(_effectivePreferencesStore);

  Future<bool> getSavedPrefs() async {
    await _coreEngine.loadSavedPrefs(_effectivePreferencesStore);
    return true;
  }

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

    if (await _effectiveStoreLauncher.canLaunch(appStoreListingURL)) {
      try {
        await _effectiveStoreLauncher.launch(
          appStoreListingURL,
          isAndroid: state.upgraderOS.isAndroid,
        );
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: launch to app store failed: $e');
        }
      }
    }
  }

  void installPackageInfo({PackageInfo? packageInfo}) {
    updateState(_state.copyWith(packageInfo: packageInfo), updateTheVersionInfo: true);
  }

  String? get currentAppStoreListingURL => _coreEngine.currentAppStoreListingURL;
  String? get currentAppStoreVersion => _coreEngine.currentAppStoreVersion;
  String? get currentInstalledVersion => _state.packageInfo?.version;
  String? get releaseNotes => _coreEngine.releaseNotes;
  String? get minAppVersion => _state.minAppVersion?.toString();
  set minAppVersion(String? version) {
    if (version == null) {
      updateState(_state.copyWithNull(minAppVersion: true), updateTheVersionInfo: true);
    } else {
      final parsedVersion = core.UpgraderEngine.parseVersion(version, 'minAppVersion', state.debugLogging);
      if (parsedVersion != null) {
        updateState(_state.copyWith(minAppVersion: parsedVersion), updateTheVersionInfo: true);
      }
    }
  }

  core.UpgraderVersionInfo? get versionInfo => _coreEngine.versionInfo;
}

PackageInfo _toPackageInfo(core.UpgraderPackageInfo packageInfo) {
  return PackageInfo(
    appName: packageInfo.appName,
    packageName: packageInfo.packageName,
    version: packageInfo.version,
    buildNumber: packageInfo.buildNumber,
  );
}

class _SharedPreferencesStore implements core.UpgraderPreferencesStore {
  const _SharedPreferencesStore();

  static const instance = _SharedPreferencesStore();

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async => (await _prefs).getString(key);

  @override
  Future<void> remove(String key) async {
    await (await _prefs).remove(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _prefs).setString(key, value);
  }
}

class _PackageInfoAppInfoProvider implements core.UpgraderAppInfoProvider {
  const _PackageInfoAppInfoProvider();

  @override
  Future<core.UpgraderPackageInfo?> getPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return core.UpgraderPackageInfo(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

class _UrlLauncherStoreLauncher implements core.UpgraderStoreLauncher {
  const _UrlLauncherStoreLauncher();

  @override
  Future<bool> canLaunch(String url) => canLaunchUrl(Uri.parse(url));

  @override
  Future<void> launch(String url, {required bool isAndroid}) async {
    await launchUrl(
      Uri.parse(url),
      mode: isAndroid
          ? LaunchMode.externalNonBrowserApplication
          : LaunchMode.platformDefault,
    );
  }
}
