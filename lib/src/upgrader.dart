/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import 'appcast.dart';
import 'itunes_search_api.dart';

/// Signature of callbacks that have no arguments and return bool.
typedef BoolCallback = bool Function();

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

  /// The ignore button title, which defaults to ```Ignore```
  String buttonTitleIgnore = 'Ignore'.toUpperCase();

  /// The later button title, which defaults to ```Later```
  String buttonTitleLater = 'Later'.toUpperCase();

  /// The update button title, which defaults to ```Update Now```
  String buttonTitleUpdate = 'Update Now'.toUpperCase();

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client client = http.Client();

  /// Days until alerting user again
  int daysUntilAlertAgain = 3;

  /// For debugging, always force the upgrade to be available.
  bool debugDisplayAlways = false;

  /// For debugging, display the upgrade at least once once.
  bool debugDisplayOnce = false;

  /// Enable print statements for debugging.
  bool debugLogging = false;

  final notInitializedExceptionMessage =
      'initialize() not called. Must be called first.';

  String prompt = 'Would you like to update it now?';

  /// The alert dialog title
  String title = 'Update App?';

  /// The alert dialog message use string with parameters: \${appName}, \${currentAppStoreVersion},  \${currentInstalledVersion} - you can also use it without parameters.
  String alertMessage =
      'A new version of \${appName} is available! Version \${currentAppStoreVersion} is now available-you have \${currentInstalledVersion}.';

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

  bool _displayed = false;
  bool _initCalled = false;
  PackageInfo _packageInfo;
  String _countryCode;

  String _installedVersion;
  String _appStoreVersion;
  String _appStoreListingURL;
  String _updateAvailable;
  DateTime _lastTimeAlerted;
  String _lastVersionAlerted;
  String _userIgnoredVersion;
  bool _hasAlerted = false;

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

    await _getSavedPrefs();

    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
      if (debugLogging) {
        print(
            'upgrader: package info packageName: ${_packageInfo.packageName}');
        print('upgrader: package info version: ${_packageInfo.version}');
      }
    }

    // Get the current locale of the device (TBD), defaulting to US.
    _countryCode ??= 'US';

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

      final appcast = Appcast();
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
          showIgnore = false;
          showLater = false;
        }
      }
    } else {
//      // If this platform is not iOS, skip the iTunes lookup
//      if (!Platform.isIOS) {
//        return false;
//      }

      if (_packageInfo == null || _packageInfo.packageName.isEmpty) {
        return false;
      }

      final iTunes = ITunesSearchAPI();
      iTunes.client = client;
      final country = _countryCode;
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
//    return 'A new version of ${appName()} is available! Version ${currentAppStoreVersion()} is now available-you have ${currentInstalledVersion()}.';

    return alertMessage
        .replaceAll('\${appName}', appName())
        .replaceAll('\${currentAppStoreVersion}', currentAppStoreVersion())
        .replaceAll('\${currentInstalledVersion}', currentInstalledVersion());
  }

  void checkVersion({@required BuildContext context}) {
    if (!_displayed) {
      if (shouldDisplayUpgrade()) {
        _displayed = true;
        Future.delayed(Duration(milliseconds: 0), () {
          _showDialog(
              context: context,
              title: title,
              message: message(),
              canDismissDialog: canDismissDialog);
        });
      }
    }
  }

  bool shouldDisplayUpgrade() {
    if (debugDisplayAlways || (debugDisplayOnce && !_hasAlerted)) {
      return true;
    }

    if (isTooSoon() || alreadyIgnoredThisVersion() || !isUpdateAvailable()) {
      return false;
    }
    return true;
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted);
    return lastAlertedDuration.inDays < daysUntilAlertAgain;
  }

  bool alreadyIgnoredThisVersion() {
    return _userIgnoredVersion != null &&
        _userIgnoredVersion == _appStoreVersion;
  }

  bool isUpdateAvailable() {
    if (_appStoreVersion == null || _installedVersion == null) {
      return false;
    }

    if (_updateAvailable == null) {
      final appStoreVersion = Version.parse(_appStoreVersion);
      final installedVersion = Version.parse(_installedVersion);

      final available = appStoreVersion > installedVersion;
      _updateAvailable = available ? _appStoreVersion : null;

      if (debugLogging) {
        print('upgrader: appStoreVersion: $_appStoreVersion');
        print('upgrader: installedVersion: $_installedVersion');
        print('upgrader: isUpdateAvailable: $available');
      }
    }
    return _updateAvailable != null;
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
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              Padding(padding: EdgeInsets.only(top: 15.0), child: Text(prompt)),
            ],
          ),
          actions: <Widget>[
            if (showIgnore)
              FlatButton(
                  child: Text(buttonTitleIgnore),
                  onPressed: () => onUserIgnored(context, true)),
            if (showLater)
              FlatButton(
                  child: Text(buttonTitleLater),
                  onPressed: () => onUserLater(context, true)),
            FlatButton(
                child: Text(buttonTitleUpdate),
                onPressed: () => onUserUpdated(context, true)),
          ],
        );
      },
    );
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: $buttonTitleIgnore');
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
      print('upgrader: button tapped: $buttonTitleLater');
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
      print('upgrader: button tapped: $buttonTitleUpdate');
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
      await launch(_appStoreListingURL);
    } else {}
  }
}
