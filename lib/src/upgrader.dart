/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'appcast.dart';
import 'itunes_search_api.dart';
import 'upgrade_messages.dart';

/// Signature of callbacks that have no arguments and return bool.
typedef BoolCallback = bool Function();

/// There are two different dialog styles: Cupertino and Material
enum UpgradeDialogStyle { cupertino, material }

/// A class to define the configuration for the appcast. The configuration
/// contains two parts: a URL to the appcast, and a list of supported OS
/// names, such as "android", "ios".
class AppcastConfiguration {
  final List<String> supportedOS;
  final String url;

  AppcastConfiguration({
    this.supportedOS,
    this.url,
  });
}

/// A singleton class to configure the upgrade dialog.
class Upgrader {
  static Upgrader _singleton = Upgrader._internal();

  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  /// When an appcast is configured for iOS, the iTunes lookup is not used.
  AppcastConfiguration appcastConfig;

  /// Provide an Appcast that can be replaced for mock testing.
  Appcast appcast;

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client client = http.Client();

  /// Duration until alerting user again
  Duration durationUntilAlertAgain = Duration(days: 3);

  /// For debugging, always force the upgrade to be available.
  bool debugDisplayAlways = false;

  /// For debugging, display the upgrade at least once once.
  bool debugDisplayOnce = false;

  /// Enable print statements for debugging.
  bool debugLogging = false;

  /// The localized messages used for display in upgrader.
  UpgraderMessages messages;

  final notInitializedExceptionMessage =
      'initialize() not called. Must be called first.';

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback onIgnore;

  /// Called when the later button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback onLater;

  /// Called when the update button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback onUpdate;

  /// Hide or show Ignore button on dialog (default: true)
  bool showIgnore = true;

  /// Hide or show Later button on dialog (default: true)
  bool showLater = true;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by alert card. (default: false)
  bool canDismissDialog = false;

  /// The country code that will override the system locale. Optional. Used only for iOS.
  String countryCode;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  String minAppVersion;

  /// The upgrade dialog style. Optional. Used only on UpgradeAlert. (default: material)
  UpgradeDialogStyle dialogStyle = UpgradeDialogStyle.material;

  bool _displayed = false;
  bool _initCalled = false;
  PackageInfo _packageInfo;

  String _installedVersion;
  String _appStoreVersion;
  String _appStoreListingURL;
  String _updateAvailable;
  DateTime _lastTimeAlerted;
  String _lastVersionAlerted;
  String _userIgnoredVersion;
  bool _hasAlerted = false;
  bool _isCriticalUpdate = false;

  factory Upgrader() {
    return _singleton;
  }

  Upgrader._internal();

  void installPackageInfo({PackageInfo packageInfo}) {
    _packageInfo = packageInfo;
    _initCalled = false;
  }

  void installAppStoreVersion(String version) {
    _appStoreVersion = version;
  }

  void installAppStoreListingURL(String url) {
    _appStoreListingURL = url;
  }

  Future<bool> initialize() async {
    if (_initCalled) {
      return true;
    }

    _initCalled = true;

    messages ??= UpgraderMessages();
    if (messages.languageCode == null || messages.languageCode.isEmpty) {
      print('upgrader: error -> languageCode is empty');
    } else if (debugLogging) {
      print('upgrader: languageCode: ${messages.languageCode}');
    }

    await _getSavedPrefs();

    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
      if (debugLogging) {
        print(
            'upgrader: package info packageName: ${_packageInfo.packageName}');
        print('upgrader: package info appName: ${_packageInfo.appName}');
        print('upgrader: package info version: ${_packageInfo.version}');
      }
    }

    await _updateVersionInfo();

    _installedVersion = _packageInfo.version;

    return true;
  }

  Future<bool> _updateVersionInfo() async {
    // If there is an appcast for this platform
    if (_isAppcastThisPlatform()) {
      if (debugLogging) {
        print('upgrader: appcast is available for this platform');
      }

      final appcast = this.appcast ?? Appcast(client: client);
      await appcast.parseAppcastItemsFromUri(appcastConfig.url);
      if (debugLogging) {
        var count = appcast.items == null ? 0 : appcast.items.length;
        print('upgrader: appcast item count: $count');
      }
      final bestItem = appcast.bestItem();
      if (bestItem != null &&
          bestItem.versionString != null &&
          bestItem.versionString.isNotEmpty) {
        if (debugLogging) {
          print(
              'upgrader: appcast best item version: ${bestItem.versionString}');
        }
        _appStoreVersion ??= bestItem.versionString;
        _appStoreListingURL ??= bestItem.fileURL;
        if (bestItem.isCriticalUpdate) {
          _isCriticalUpdate = true;
        }
      }
    } else {
      // If this platform is not iOS, skip the iTunes lookup
      if (Platform.isAndroid) {
        return false;
      }

      if (_packageInfo == null ||
          _packageInfo.packageName == null ||
          _packageInfo.packageName.isEmpty) {
        return false;
      }

      // The  country code of the locale, defaulting to `US`.
      final code = countryCode ?? findCountryCode();
      if (debugLogging) {
        print('upgrader: countryCode: $code');
      }

      final iTunes = ITunesSearchAPI();
      iTunes.client = client;
      final country = code;
      final response = await iTunes.lookupByBundleId(_packageInfo.packageName,
          country: country);

      _appStoreVersion ??= ITunesResults.version(response);
      _appStoreListingURL ??= ITunesResults.trackViewUrl(response);
    }

    return true;
  }

  bool _isAppcastThisPlatform() {
    if (appcastConfig == null ||
        appcastConfig.url == null ||
        appcastConfig.url.isEmpty) {
      return false;
    }

    // Since this appcast config contains a URL, this appcast is valid.
    // However, if the supported OS is not listed, it is not supported.
    // When there are no supported OSes listed, they are all supported.
    var supported = true;
    if (appcastConfig.supportedOS != null) {
      supported = appcastConfig.supportedOS.contains(Platform.operatingSystem);
    }
    return supported;
  }

  bool _verifyInit() {
    if (!_initCalled) {
      throw (notInitializedExceptionMessage);
    }
    return true;
  }

  String appName() {
    _verifyInit();
    return _packageInfo.appName;
  }

  String currentAppStoreListingURL() {
    return _appStoreListingURL;
  }

  String currentAppStoreVersion() {
    return _appStoreVersion;
  }

  String currentInstalledVersion() {
    return _installedVersion;
  }

  String message() {
    var msg = messages.message(UpgraderMessage.body);
    msg = msg.replaceAll('{{appName}}', appName() ?? '');
    msg = msg.replaceAll(
        '{{currentAppStoreVersion}}', currentAppStoreVersion() ?? '');
    msg = msg.replaceAll(
        '{{currentInstalledVersion}}', currentInstalledVersion() ?? '');
    return msg;
  }

  void checkVersion({@required BuildContext context}) {
    if (!_displayed) {
      final shouldDisplay = shouldDisplayUpgrade();
      if (debugLogging) {
        print('upgrader: shouldDisplayUpgrade: $shouldDisplay');
      }
      if (shouldDisplay) {
        _displayed = true;
        Future.delayed(Duration(milliseconds: 0), () {
          _showDialog(
              context: context,
              title: messages.message(UpgraderMessage.title),
              message: message(),
              canDismissDialog: canDismissDialog);
        });
      }
    }
  }

  bool blocked() {
    return belowMinAppVersion() || _isCriticalUpdate;
  }

  bool shouldDisplayUpgrade() {
    final isBlocked = blocked();

    if (debugLogging) {
      print('upgrader: blocked: $isBlocked');
      print('upgrader: debugDisplayAlways: $debugDisplayAlways');
      print('upgrader: debugDisplayOnce: $debugDisplayOnce');
      print('upgrader: hasAlerted: $_hasAlerted');
    }

    // If installed version is below minimum app version, or is a critical update,
    // disable ignore and later buttons.
    if (isBlocked) {
      showIgnore = false;
      showLater = false;
    }
    if (debugDisplayAlways || (debugDisplayOnce && !_hasAlerted)) {
      return true;
    }
    if (!isUpdateAvailable()) {
      return false;
    }
    if (isBlocked) {
      return true;
    }
    if (isTooSoon() || alreadyIgnoredThisVersion()) {
      return false;
    }
    return true;
  }

  /// Is installed version below minimum app version?
  bool belowMinAppVersion() {
    var rv = false;
    if (minAppVersion != null) {
      try {
        final minVersion = Version.parse(minAppVersion);
        final installedVersion = Version.parse(_installedVersion);
        rv = installedVersion < minVersion;
      } catch (e) {
        print(e);
      }
    }
    return rv;
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted);
    return lastAlertedDuration < durationUntilAlertAgain;
  }

  bool alreadyIgnoredThisVersion() {
    return _userIgnoredVersion != null &&
        _userIgnoredVersion == _appStoreVersion;
  }

  bool isUpdateAvailable() {
    if (debugLogging) {
      print('upgrader: appStoreVersion: $_appStoreVersion');
      print('upgrader: installedVersion: $_installedVersion');
      print('upgrader: minAppVersion: $minAppVersion');
    }
    if (_appStoreVersion == null || _installedVersion == null) {
      if (debugLogging) {
        print('upgrader: isUpdateAvailable: false');
      }
      return false;
    }

    if (_updateAvailable == null) {
      final appStoreVersion = Version.parse(_appStoreVersion);
      final installedVersion = Version.parse(_installedVersion);

      final available = appStoreVersion > installedVersion;
      _updateAvailable = available ? _appStoreVersion : null;
    }
    if (debugLogging) {
      print('upgrader: isUpdateAvailable: ${_updateAvailable != null}');
    }
    return _updateAvailable != null;
  }

  /// Determine the current country code, either from the context, or
  /// from the system-reported default locale of the device. The default
  /// is `US`.
  String findCountryCode({BuildContext context}) {
    Locale locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = WidgetsBinding.instance.window.locale;
    }
    final code = locale == null || locale.countryCode == null
        ? 'US'
        : locale.countryCode;
    return code;
  }

  void _showDialog(
      {@required BuildContext context,
      @required String title,
      @required String message,
      bool canDismissDialog}) {
    if (debugLogging) {
      print('upgrader: showDialog title: $title');
      print('upgrader: showDialog message: $message');
    }

    // Save the date/time as the last time alerted.
    saveLastAlerted();

    showDialog(
      barrierDismissible: canDismissDialog,
      context: context,
      builder: (BuildContext context) {
        return dialogStyle == UpgradeDialogStyle.material
            ? _alertDialog(title, message, context)
            : _cupertinoAlertDialog(title, message, context);
      },
    );
  }

  AlertDialog _alertDialog(String title, String message, BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message),
          Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Text(messages.message(UpgraderMessage.prompt))),
        ],
      ),
      actions: <Widget>[
        if (showIgnore)
          TextButton(
              child: Text(messages.message(UpgraderMessage.buttonTitleIgnore)),
              onPressed: () => onUserIgnored(context, true)),
        if (showLater)
          TextButton(
              child: Text(messages.message(UpgraderMessage.buttonTitleLater)),
              onPressed: () => onUserLater(context, true)),
        TextButton(
            child: Text(messages.message(UpgraderMessage.buttonTitleUpdate)),
            onPressed: () => onUserUpdated(context, !blocked())),
      ],
    );
  }

  CupertinoAlertDialog _cupertinoAlertDialog(
      String title, String message, BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(message),
          Padding(
              padding: EdgeInsets.only(top: 15.0),
              child: Text(messages.message(UpgraderMessage.prompt))),
        ],
      ),
      actions: <Widget>[
        if (showIgnore)
          CupertinoDialogAction(
              child: Text(messages.message(UpgraderMessage.buttonTitleIgnore)),
              onPressed: () => onUserIgnored(context, true)),
        if (showLater)
          CupertinoDialogAction(
              child: Text(messages.message(UpgraderMessage.buttonTitleLater)),
              onPressed: () => onUserLater(context, true)),
        CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(messages.message(UpgraderMessage.buttonTitleUpdate)),
            onPressed: () => onUserUpdated(context, !blocked())),
      ],
    );
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onIgnore != null) {
      doProcess = onIgnore();
    }

    if (doProcess) {
      _saveIgnored();
    }

    if (shouldPop) {
      _pop(context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onLater != null) {
      doProcess = onLater();
    }

    if (doProcess) {}

    if (shouldPop) {
      _pop(context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onUpdate != null) {
      doProcess = onUpdate();
    }

    if (doProcess) {
      _sendUserToAppStore();
    }

    if (shouldPop) {
      _pop(context);
    }
  }

  Future<bool> clearSavedSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('userIgnoredVersion');
    await prefs.remove('lastTimeAlerted');
    await prefs.remove('lastVersionAlerted');

    _userIgnoredVersion = null;
    _lastTimeAlerted = null;
    _lastVersionAlerted = null;

    return true;
  }

  static void resetSingleton() {
    _singleton = Upgrader._internal();
  }

  void _pop(BuildContext context) {
    Navigator.of(context).pop();
    _displayed = false;
  }

  Future<bool> _saveIgnored() async {
    var prefs = await SharedPreferences.getInstance();

    _userIgnoredVersion = _appStoreVersion;
    await prefs.setString('userIgnoredVersion', _userIgnoredVersion);
    return true;
  }

  Future<bool> saveLastAlerted() async {
    var prefs = await SharedPreferences.getInstance();
    _lastTimeAlerted = DateTime.now();
    await prefs.setString('lastTimeAlerted', _lastTimeAlerted.toString());

    _lastVersionAlerted = _appStoreVersion;
    await prefs.setString('lastVersionAlerted', _lastVersionAlerted);

    _hasAlerted = true;
    return true;
  }

  Future<bool> _getSavedPrefs() async {
    var prefs = await SharedPreferences.getInstance();
    final lastTimeAlerted = prefs.getString('lastTimeAlerted');
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    _lastVersionAlerted = prefs.getString('lastVersionAlerted');

    _userIgnoredVersion = prefs.getString('userIgnoredVersion');

    return true;
  }

  void _sendUserToAppStore() async {
    if (_appStoreListingURL == null || _appStoreListingURL.isEmpty) {
      if (debugLogging) {
        print('upgrader: empty _appStoreListingURL');
      }
      return;
    }

    if (debugLogging) {
      print('upgrader: launching: $_appStoreListingURL');
    }

    if (await canLaunch(_appStoreListingURL)) {
      try {
        await launch(_appStoreListingURL);
      } catch (e) {
        if (debugLogging) {
          print('upgrader: launch to app store failed: $e');
        }
      }
    } else {}
  }
}
