/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';
import 'itunes_search_api.dart';

/// A widget to display the upgrade dialog.
class UpgradeAlert extends StatelessWidget {
  /// The [child] contained by the widget.
  final Widget child;

  /// The ignore button title, which defaults to ```Ignore```
  final String buttonTitleIgnore;

  /// The remind button title, which defaults to ```Remind```
  final String buttonTitleRemind;

  /// The update button title, which defaults to ```Update Now```
  final String buttonTitleUpdate;

  /// The call to action message, which defaults to: Would you like to update it now?
  final String prompt;

  /// The title of the alert dialog. Defaults to: Update App?
  final String title;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  UpgradeAlert({
    Key key,
    this.buttonTitleIgnore,
    this.buttonTitleRemind,
    this.buttonTitleUpdate,
    this.child,
    this.prompt,
    this.title,
    this.client,
  }) : super(key: key) {
    if (this.buttonTitleIgnore != null) {
      Upgrader().buttonTitleIgnore = this.buttonTitleIgnore;
    }
    if (this.buttonTitleRemind != null) {
      Upgrader().buttonTitleRemind = this.buttonTitleRemind;
    }
    if (this.buttonTitleUpdate != null) {
      Upgrader().buttonTitleUpdate = this.buttonTitleUpdate;
    }
    if (this.client != null) {
      Upgrader().client = this.client;
    }
    if (this.prompt != null) {
      Upgrader().prompt = this.prompt;
    }
    if (this.title != null) {
      Upgrader().title = this.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Upgrader().debugEnabled) {
      print('upgrader: build UpgradeWidget');
    }

    return FutureBuilder(
        future: Upgrader().initialize(),
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done) {
            Upgrader().checkVersion(context: context);
          }
          return child;
        });
  }
}

/// A singleton class to configure the upgrade dialog.
class Upgrader {
  static final Upgrader _singleton = new Upgrader._internal();

  String buttonTitleIgnore = 'Ignore'.toUpperCase();
  String buttonTitleRemind = 'Later'.toUpperCase();
  String buttonTitleUpdate = 'Update Now'.toUpperCase();

  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client client = http.Client();

  /// Enable print statements for debugging.
  bool debugEnabled = false;

  /// Days until alerting user again
  int daysToAlertAgain = 3;

  final notInitializedExceptionMessage =
      'initialize() not called. Must be called first.';

  String prompt = 'Would you like to update it now?';

  /// The alert dialog title
  String title = 'Update App?';


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
      if (debugEnabled) {
        print(
            'upgrader: package info packageName: ${_packageInfo.packageName}');
        print('upgrader: package info version: ${_packageInfo.version}');
      }
    }

    await _updateAppStoreDetails();

    _installedVersion = _packageInfo.version;

    return true;
  }

  Future<bool> _updateAppStoreDetails() async {
    if (_packageInfo == null || _packageInfo.packageName.length == 0) {
      return false;
    }

    // TODO: add support for the Android Play Store

    final iTunes = ITunesSearchAPI();
    iTunes.client = this.client;
    final response = await iTunes.lookupByBundleId(_packageInfo.packageName);

    if (_appStoreVersion == null) {
      _appStoreVersion = ITunesResults.version(response);
    }
    if (_appStoreListingURL == null) {
      _appStoreListingURL = ITunesResults.trackViewUrl(response);
    }

    return true;
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
    return 'A new version of ${appName()} is available! Version ${currentAppStoreVersion()} is now available-you have ${currentInstalledVersion()}.';
  }

  void checkVersion({@required BuildContext context}) {
    if (isTooSoon() ||
        alreadyIgnoredThisVersion() ||
        alreadyAnsweredThisVersion() ||
        !isUpdateAvailable()) {
      return;
    }

    if (!_displayed) {
      _displayed = true;
      Future.delayed(Duration(milliseconds: 0), () {
        _showDialog(context: context, title: title, message: message());
      });
    }
  }

  bool isTooSoon() {
    if (_lastTimeAlerted == null) {
      return false;
    }

    final lastAlertedDuration = DateTime.now().difference(_lastTimeAlerted);
    return lastAlertedDuration.inDays < daysToAlertAgain;
  }

  bool alreadyAnsweredThisVersion() {
    return false;
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

      if (debugEnabled) {
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
      @required String message}) {
    if (debugEnabled) {
      print('upgrader: showDialog title: $title');
      print('upgrader: showDialog message: $message');
    }

    // Save the date/time as the last time alerted.
    _saveLastAlerted();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message),
              Padding(
                  padding: EdgeInsets.only(top: 15.0), child: Text(prompt)),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(buttonTitleIgnore),
              onPressed: () {
                if (debugEnabled) {
                  print('upgrader: button tapped: $buttonTitleIgnore');
                }

                _onUserIgnored();

                Navigator.of(context).pop();
                _displayed = false;
              },
            ),
            FlatButton(
              child: Text(buttonTitleRemind),
              onPressed: () {
                if (debugEnabled) {
                  print('upgrader: button tapped: $buttonTitleRemind');
                }

                Navigator.of(context).pop();
                _displayed = false;
              },
            ),
            FlatButton(
              child: Text(buttonTitleUpdate),
              onPressed: () {
                if (debugEnabled) {
                  print('upgrader: button tapped: $buttonTitleUpdate');
                }

                Navigator.of(context).pop();
                _displayed = false;

                _sendUserToAppStore();
              },
            ),
          ],
        );
      },
    );
  }

  void _onUserIgnored() {
    _saveIgnored();
  }

  void clearSavedSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('userIgnoredVersion');
    prefs.remove('lastTimeAlerted');
    prefs.remove('lastVersionAlerted');

    _userIgnoredVersion = null;
    _lastTimeAlerted = null;
    _lastVersionAlerted = null;
  }

  Future<bool> _saveIgnored() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    _userIgnoredVersion = _appStoreVersion;
    prefs.setString('userIgnoredVersion', _userIgnoredVersion);
    return true;
  }

  Future<bool> _saveLastAlerted() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _lastTimeAlerted = DateTime.now();
    prefs.setString('lastTimeAlerted', _lastTimeAlerted.toString());

    _lastVersionAlerted = _appStoreVersion;
    prefs.setString('lastVersionAlerted', _lastVersionAlerted);
    return true;
  }

  Future<bool> _getSavedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final lastTimeAlerted = prefs.getString('lastTimeAlerted');
    if (lastTimeAlerted != null) {
      _lastTimeAlerted = DateTime.parse(lastTimeAlerted);
    }

    _lastVersionAlerted = prefs.getString('lastVersionAlerted');

    _userIgnoredVersion = prefs.getString('userIgnoredVersion');

    return true;
  }

  void _sendUserToAppStore() async {
    if (_appStoreListingURL == null || _appStoreListingURL.length == 0) {
      if (debugEnabled) {
        print('upgrader: empty _appStoreListingURL');
      }
      return;
    }

    if (debugEnabled) {
      print('upgrader: launching: $_appStoreListingURL');
    }

    if (await canLaunch(_appStoreListingURL)) {
      launch(_appStoreListingURL);
    } else {}
  }
}
