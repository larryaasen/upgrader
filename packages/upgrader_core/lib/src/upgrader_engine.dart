import 'package:version/version.dart';

import 'upgrade_state.dart';
import 'upgrade_store_controller.dart';
import 'upgrader_interfaces.dart';
import 'upgrader_version_info.dart';

typedef WillDisplayUpgradeCallback = void Function({
  required bool display,
  String? installedVersion,
  UpgraderVersionInfo? versionInfo,
});

class UpgraderEngine {
  UpgraderEngine({
    required UpgraderState state,
    UpgraderStoreController? storeController,
    this.willDisplayUpgrade,
  })  : _state = state,
        storeController = storeController ?? UpgraderStoreController();

  static const userIgnoredVersionKey = 'userIgnoredVersion';
  static const lastTimeAlertedKey = 'lastTimeAlerted';
  static const lastVersionAlertedKey = 'lastVersionAlerted';

  UpgraderStoreController storeController;
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  UpgraderState _state;
  UpgraderState get state => _state;

  bool initialized = false;
  Version? _updateAvailable;
  DateTime? _lastTimeAlerted;
  Version? _lastVersionAlerted;
  Version? _userIgnoredVersion;
  bool _hasAlerted = false;

  void markInitialized() {
    initialized = true;
  }

  void updateState(UpgraderState newState) {
    _state = newState;
  }

  Future<UpgraderVersionInfo?> updateVersionInfo({
    String? countryCode,
    String? languageCode,
  }) async {
    if (state.packageInfo == null || state.packageInfo!.packageName.isEmpty) {
      updateState(state.copyWithNull(versionInfo: true));
      return null;
    }

    late Version installedVersion;
    try {
      installedVersion = Version.parse(state.packageInfo!.version);
    } catch (e) {
      if (state.debugLogging) {
        print('upgrader: installedVersion exception: $e');
      }
      updateState(state.copyWithNull(versionInfo: true));
      return null;
    }

    final store = storeController.getUpgraderStore(state.upgraderPlatform);
    if (store == null) {
      if (state.debugLogging) {
        print('upgrader: updateVersionInfo found no store controller');
      }
      updateState(state.copyWithNull(versionInfo: true));
      return null;
    }

    final versionInfo = await store.getVersionInfo(
      state: state,
      installedVersion: installedVersion,
      country: state.countryCodeOverride ?? countryCode,
      language: state.languageCodeOverride ?? languageCode,
    );

    updateState(state.copyWith(versionInfo: versionInfo));
    return versionInfo;
  }

  String appName() => state.packageInfo?.appName ?? '';

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

    bool shouldDisplay = true;
    if (state.debugDisplayAlways || (state.debugDisplayOnce && !_hasAlerted)) {
      shouldDisplay = true;
    } else if (!isUpdateAvailable()) {
      shouldDisplay = false;
    } else if (isBlocked) {
      shouldDisplay = true;
    } else if (state.showOnlyMandatoryUpdates) {
      shouldDisplay = false;
    } else if (isTooSoon() || alreadyIgnoredThisVersion()) {
      shouldDisplay = false;
    }

    if (state.debugLogging) {
      print('upgrader: shouldDisplayUpgrade: $shouldDisplay');
    }

    willDisplayUpgrade?.call(
      display: shouldDisplay,
      installedVersion: state.packageInfo?.version,
      versionInfo: versionInfo,
    );

    return shouldDisplay;
  }

  bool belowMinAppVersion() {
    var result = false;
    final minVersion = state.minAppVersion ?? versionInfo?.minAppVersion;
    if (minVersion != null && state.packageInfo != null) {
      try {
        final installedVersion = Version.parse(state.packageInfo!.version);
        result = installedVersion < minVersion;
      } catch (e) {
        if (state.debugLogging) {
          print(e);
        }
      }
    }
    return result;
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    if (_lastVersionAlerted != null &&
        versionInfo?.appStoreVersion != null &&
        _lastVersionAlerted != versionInfo?.appStoreVersion) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted!);
    final result = lastAlertedDuration < state.durationUntilAlertAgain;
    if (result && state.debugLogging) {
      print('upgrader: isTooSoon: true');
    }
    return result;
  }

  bool alreadyIgnoredThisVersion() {
    final result =
        _userIgnoredVersion != null && _userIgnoredVersion == versionInfo?.appStoreVersion;
    if (result && state.debugLogging) {
      print('upgrader: alreadyIgnoredThisVersion: true');
    }
    return result;
  }

  bool isUpdateAvailable() {
    if (state.debugLogging) {
      print('upgrader: installedVersion: ${state.packageInfo?.version}');
      print('upgrader: minAppVersion: ${state.minAppVersion}');
    }
    if (versionInfo?.appStoreVersion == null || state.packageInfo?.version == null) {
      if (state.debugLogging) {
        print('upgrader: isUpdateAvailable: false');
      }
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
    if (state.debugLogging) {
      print('upgrader: isUpdateAvailable: $isAvailable');
    }
    return isAvailable;
  }

  Future<void> loadSavedPrefs(UpgraderPreferencesStore preferencesStore) async {
    final lastTimeAlerted = await preferencesStore.getString(lastTimeAlertedKey);
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    final versionAlerted = await preferencesStore.getString(lastVersionAlertedKey);
    if (versionAlerted != null) {
      try {
        _lastVersionAlerted = Version.parse(versionAlerted);
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: lastVersionAlerted exception: $e');
        }
      }
    }

    final ignoredVersion = await preferencesStore.getString(userIgnoredVersionKey);
    if (ignoredVersion != null) {
      try {
        _userIgnoredVersion = Version.parse(ignoredVersion);
      } catch (e) {
        if (state.debugLogging) {
          print('upgrader: userIgnoredVersion exception: $e');
        }
      }
    }
  }

  Future<bool> saveIgnored(UpgraderPreferencesStore preferencesStore) async {
    _userIgnoredVersion = versionInfo?.appStoreVersion;
    await preferencesStore.setString(
      userIgnoredVersionKey,
      _userIgnoredVersion?.toString() ?? '',
    );
    return true;
  }

  Future<bool> saveLastAlerted(UpgraderPreferencesStore preferencesStore) async {
    _lastTimeAlerted = DateTime.now();
    await preferencesStore.setString(lastTimeAlertedKey, _lastTimeAlerted.toString());

    _lastVersionAlerted = versionInfo?.appStoreVersion;
    await preferencesStore.setString(
      lastVersionAlertedKey,
      _lastVersionAlerted?.toString() ?? '',
    );

    _hasAlerted = true;
    return true;
  }

  static Future<void> clearSavedSettings(
    UpgraderPreferencesStore preferencesStore,
  ) async {
    await preferencesStore.remove(userIgnoredVersionKey);
    await preferencesStore.remove(lastTimeAlertedKey);
    await preferencesStore.remove(lastVersionAlertedKey);
  }

  static Version? parseVersion(String? version, String name, bool debugLogging) {
    if (version == null) {
      return null;
    }
    try {
      return Version.parse(version);
    } catch (e) {
      if (debugLogging) {
        print('upgrader: _parseVersion $name exception: $e');
      }
      return null;
    }
  }

  UpgraderVersionInfo? get versionInfo => state.versionInfo;
  String? get currentAppStoreListingURL => state.versionInfo?.appStoreListingURL;
  String? get currentAppStoreVersion => state.versionInfo?.appStoreVersion?.toString();
  String? get currentInstalledVersion => state.packageInfo?.version;
  String? get releaseNotes => state.versionInfo?.releaseNotes;
}
