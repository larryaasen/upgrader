/*
 * Copyright (c) 2018-2023 Larry Aasen. All rights reserved.
 */

import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
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

typedef Content = Widget Function(
  String appName,
  String appStoreVersion,
  String appInstalledVersion,
  VoidCallback onUpdate,
);

/// Signature of callbacks that have a bool argument and no return.
typedef VoidBoolCallback = void Function(bool value);

/// Signature of callback for willDisplayUpgrade. Includes display,
/// minAppVersion, installedVersion, and appStoreVersion.
typedef WillDisplayUpgradeCallback = void Function(
    {required bool display,
    String? minAppVersion,
    String? installedVersion,
    String? appStoreVersion});

/// The type of data in the stream.
typedef UpgraderEvaluateNeed = bool;

/// There are two different dialog styles: Cupertino and Material
enum UpgradeDialogStyle { cupertino, material }

/// A class to define the configuration for the appcast. The configuration
/// contains two parts: a URL to the appcast, and a list of supported OS
/// names, such as "android", "fuchsia", "ios", "linux" "macos", "web", "windows".
class AppcastConfiguration {
  final List<String>? supportedOS;
  final String? url;

  AppcastConfiguration({
    this.supportedOS,
    this.url,
  });
}

/// Creates a shared instance of [Upgrader].
Upgrader _sharedInstance = Upgrader();

/// A class to configure the upgrade dialog.
class Upgrader with WidgetsBindingObserver {
  /// Provide an Appcast that can be replaced for mock testing.
  final Appcast? appcast;

  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  /// When an appcast is configured for iOS, the iTunes lookup is not used.
  final AppcastConfiguration? appcastConfig;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by [UpgradeCard]. (default: false)
  bool canDismissDialog;

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

  /// The upgrade dialog style. Used only on UpgradeAlert. (default: material)
  UpgradeDialogStyle dialogStyle;

  /// Duration until alerting user again
  final Duration durationUntilAlertAgain;

  /// The localized messages used for display in upgrader.
  UpgraderMessages messages;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  String? minAppVersion;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onIgnore;

  /// Called when the later button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onLater;

  /// Called when the update button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  BoolCallback? onUpdate;

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Not used by [UpgradeCard].
  BoolCallback? shouldPopScope;

  /// Hide or show Ignore button on dialog (default: true)
  bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  bool showLater;

  /// Hide or show release notes (default: true)
  bool showReleaseNotes;

  /// The text style for the cupertino dialog buttons. Used only for
  /// [UpgradeDialogStyle.cupertino]. Optional.
  TextStyle? cupertinoButtonTextStyle;

  /// Called when [Upgrader] determines that an upgrade may or may not be
  /// displayed. The [value] parameter will be true when it should be displayed,
  /// and false when it should not be displayed. One good use for this callback
  /// is logging metrics for your app.
  WillDisplayUpgradeCallback? willDisplayUpgrade;

  /// Provides information on which OS this code is running on.
  final UpgraderOS upgraderOS;

  Route<dynamic>? _route;
  BuildContext? _context;

  bool _displayed = false;
  bool _initCalled = false;

  PackageInfo? _packageInfo;

  String? _installedVersion;
  String? _appStoreVersion;
  String? _appStoreListingURL;
  String? _releaseNotes;
  String? _updateAvailable;
  DateTime? _lastTimeAlerted;
  String? _lastVersionAlerted;
  String? _userIgnoredVersion;
  bool _hasAlerted = false;
  bool _isCriticalUpdate = false;

  /// Track the initialization future so that [initialize] can be called multiple times.
  Future<bool>? _futureInit;

  /// A stream that provides a new value each time an evaluation should be performed.
  /// The values will always be null or true.
  Stream<UpgraderEvaluateNeed> get evaluationStream => _streamController.stream;
  final _streamController = StreamController<UpgraderEvaluateNeed>.broadcast();

  /// An evaluation should be performed.
  bool get evaluationReady => _evaluationReady;
  bool _evaluationReady = false;

  static const notInitializedExceptionMessage =
      'initialize() not called. Must be called first.';

  Upgrader({
    this.appcastConfig,
    this.appcast,
    UpgraderMessages? messages,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.durationUntilAlertAgain = const Duration(days: 3),
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.willDisplayUpgrade,
    http.Client? client,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.canDismissDialog = false,
    this.countryCode,
    this.languageCode,
    this.minAppVersion,
    this.dialogStyle = UpgradeDialogStyle.material,
    this.cupertinoButtonTextStyle,
    UpgraderOS? upgraderOS,
  })  : client = client ?? http.Client(),
        messages = messages ?? UpgraderMessages(),
        upgraderOS = upgraderOS ?? UpgraderOS() {
    if (debugLogging) print("upgrader: instantiated.");
  }

  /// A shared instance of [Upgrader].
  static Upgrader get sharedInstance => _sharedInstance;

  void installPackageInfo({PackageInfo? packageInfo}) {
    _packageInfo = packageInfo;
    _initCalled = false;
  }

  void installAppStoreVersion(String version) {
    _appStoreVersion = version;
  }

  void installAppStoreListingURL(String url) {
    _appStoreListingURL = url;
  }

  /// Initialize [Upgrader] by getting saved preferences, getting platform package info, and getting
  /// released version info.
  Future<bool> initialize() async {
    if (debugLogging) {
      print('upgrader: initialize called');
    }
    if (_futureInit != null) return _futureInit!;

    _futureInit = Future(() async {
      if (debugLogging) {
        print('upgrader: initializing');
      }
      if (_initCalled) {
        assert(false, 'This should never happen.');
        return true;
      }
      _initCalled = true;

      if (messages.languageCode.isEmpty) {
        print('upgrader: error -> languageCode is empty');
      } else if (debugLogging) {
        print('upgrader: languageCode: ${messages.languageCode}');
      }

      await _getSavedPrefs();

      if (debugLogging) {
        print('upgrader: default operatingSystem: '
            '${upgraderOS.operatingSystem} ${upgraderOS.operatingSystemVersion}');
        print('upgrader: operatingSystem: ${upgraderOS.operatingSystem}');
        print('upgrader: '
            'isAndroid: ${upgraderOS.isAndroid}, '
            'isIOS: ${upgraderOS.isIOS}, '
            'isLinux: ${upgraderOS.isLinux}, '
            'isMacOS: ${upgraderOS.isMacOS}, '
            'isWindows: ${upgraderOS.isWindows}, '
            'isFuchsia: ${upgraderOS.isFuchsia}, '
            'isWeb: ${upgraderOS.isWeb}');
      }

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

      await _updateVersionInfo();

      // Add an observer of application events.
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
      await _updateVersionInfo();

      /// Trigger the stream to indicate another evaluation should be performed.
      /// The value will always be true.
      _streamController.add(true);
    }
  }

  Future<bool> _updateVersionInfo() async {
    // If there is an appcast for this platform
    if (_isAppcastThisPlatform()) {
      if (debugLogging) {
        print('upgrader: appcast is available for this platform');
      }

      final appcast = this.appcast ?? Appcast(client: client);
      await appcast.parseAppcastItemsFromUri(appcastConfig!.url!);
      if (debugLogging) {
        var count = appcast.items == null ? 0 : appcast.items!.length;
        print('upgrader: appcast item count: $count');
      }
      final criticalUpdateItem = appcast.bestCriticalItem();
      final criticalVersion = criticalUpdateItem?.versionString ?? '';

      final bestItem = appcast.bestItem();
      if (bestItem != null &&
          bestItem.versionString != null &&
          bestItem.versionString!.isNotEmpty) {
        if (debugLogging) {
          print(
              'upgrader: appcast best item version: ${bestItem.versionString}');
          print(
              'upgrader: appcast critical update item version: ${criticalUpdateItem?.versionString}');
        }

        try {
          if (criticalVersion.isNotEmpty &&
              Version.parse(_installedVersion!) <
                  Version.parse(criticalVersion)) {
            _isCriticalUpdate = true;
          }
        } catch (e) {
          print('upgrader: updateVersionInfo could not parse version info $e');
          _isCriticalUpdate = false;
        }

        _appStoreVersion = bestItem.versionString;
        _appStoreListingURL = bestItem.fileURL;
        _releaseNotes = bestItem.itemDescription;
      }
    } else {
      if (_packageInfo == null || _packageInfo!.packageName.isEmpty) {
        return false;
      }

      // The  country code of the locale, defaulting to `US`.
      final country = countryCode ?? findCountryCode();
      if (debugLogging) {
        print('upgrader: countryCode: $country');
      }

      // The  language code of the locale, defaulting to `en`.
      final language = languageCode ?? findLanguageCode();
      if (debugLogging) {
        print('upgrader: languageCode: $language');
      }

      // Get Android version from Google Play Store, or
      // get iOS version from iTunes Store.
      if (upgraderOS.isAndroid) {
        await _getAndroidStoreVersion(country: country, language: language);
      } else if (upgraderOS.isIOS) {
        final iTunes = ITunesSearchAPI();
        iTunes.debugLogging = debugLogging;
        iTunes.client = client;
        final response = await (iTunes
            .lookupByBundleId(_packageInfo!.packageName, country: country));

        if (response != null) {
          _appStoreVersion = iTunes.version(response);
          _appStoreListingURL = iTunes.trackViewUrl(response);
          _releaseNotes ??= iTunes.releaseNotes(response);
          final mav = iTunes.minAppVersion(response);
          if (mav != null) {
            minAppVersion = mav.toString();
            if (debugLogging) {
              print('upgrader: ITunesResults.minAppVersion: $minAppVersion');
            }
          }
        }
      }
    }

    return true;
  }

  /// Android info is fetched by parsing the html of the app store page.
  Future<bool?> _getAndroidStoreVersion(
      {String? country, String? language}) async {
    final id = _packageInfo!.packageName;
    final playStore = PlayStoreSearchAPI(client: client);
    playStore.debugLogging = debugLogging;
    final response =
        await (playStore.lookupById(id, country: country, language: language));
    if (response != null) {
      _appStoreVersion ??= playStore.version(response);
      _appStoreListingURL ??=
          playStore.lookupURLById(id, language: language, country: country);
      _releaseNotes ??= playStore.releaseNotes(response);
      final mav = playStore.minAppVersion(response);
      if (mav != null) {
        minAppVersion = mav.toString();
        if (debugLogging) {
          print('upgrader: PlayStoreResults.minAppVersion: $minAppVersion');
        }
      }
    }

    return true;
  }

  bool _isAppcastThisPlatform() {
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

  bool _verifyInit() {
    if (!_initCalled) {
      throw (notInitializedExceptionMessage);
    }
    return true;
  }

  String appName() {
    _verifyInit();
    return _packageInfo?.appName ?? '';
  }

  String? currentAppStoreListingURL() => _appStoreListingURL;

  String? currentAppStoreVersion() => _appStoreVersion;

  String? currentInstalledVersion() => _installedVersion;

  String? get releaseNotes => _releaseNotes;

  String message() {
    var msg = messages.message(UpgraderMessage.body)!;
    msg = msg.replaceAll('{{appName}}', appName());
    msg = msg.replaceAll(
        '{{currentAppStoreVersion}}', currentAppStoreVersion() ?? '');
    msg = msg.replaceAll(
        '{{currentInstalledVersion}}', currentInstalledVersion() ?? '');
    return msg;
  }

  /// Will show the alert dialog when it should be dispalyed.
  /// Only called by [UpgradeAlert] and not used by [UpgradeCard].
  void checkVersion({
    required BuildContext context,
    Content? content,
    Color? barrierColor,
    bool useSafeArea = true,
  }) async {
    if (!_displayed) {
      final shouldDisplay = shouldDisplayUpgrade();
      if (debugLogging) {
        print(
            'upgrader: shouldDisplayReleaseNotes: ${shouldDisplayReleaseNotes()}');
        print('upgrader: A content was passed: ${content != null}');
      }
      if (shouldDisplay) {
        _displayed = true;
        if (!_initCalled) {
          final success = await initialize();
          if (!success) {
            _displayed = false;
            print('upgrader: initialize failed');
            return;
          }
        }
        Future.delayed(const Duration(milliseconds: 0), () {
          _showDialog(
            context: context,
            barrierColor: barrierColor,
            title: messages.message(UpgraderMessage.title),
            message: message(),
            releaseNotes: shouldDisplayReleaseNotes() ? _releaseNotes : null,
            canDismissDialog: canDismissDialog,
            content: content,
            useSafeArea: useSafeArea,
          );
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
    if (willDisplayUpgrade != null) {
      willDisplayUpgrade!(
          display: rv,
          minAppVersion: minAppVersion,
          installedVersion: _installedVersion,
          appStoreVersion: _appStoreVersion);
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
    final rv =
        _userIgnoredVersion != null && _userIgnoredVersion == _appStoreVersion;
    if (rv && debugLogging) {
      print('upgrader: alreadyIgnoredThisVersion: true');
    }
    return rv;
  }

  bool isUpdateAvailable() {
    if (debugLogging) {
      print('upgrader: appStoreVersion: $_appStoreVersion');
      print('upgrader: installedVersion: $_installedVersion');
      print('upgrader: minAppVersion: $minAppVersion');
    }
    if (_appStoreVersion == null || _installedVersion == null) {
      if (debugLogging) print('upgrader: isUpdateAvailable: false');
      return false;
    }

    try {
      final appStoreVersion = Version.parse(_appStoreVersion!);
      final installedVersion = Version.parse(_installedVersion!);

      final available = appStoreVersion > installedVersion;
      _updateAvailable = available ? _appStoreVersion : null;
    } on Exception catch (e) {
      if (debugLogging) {
        print('upgrader: isUpdateAvailable: $e');
      }
    }
    final isAvailable = _updateAvailable != null;
    if (debugLogging) print('upgrader: isUpdateAvailable: $isAvailable');
    return isAvailable;
  }

  bool shouldDisplayReleaseNotes() {
    return showReleaseNotes && (_releaseNotes?.isNotEmpty ?? false);
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

  void _showDialog({
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool canDismissDialog,
    Color? barrierColor,
    bool useSafeArea = true,
    Content? content,
  }) {
    if (debugLogging) {
      print('upgrader: showDialog title: $title');
      print('upgrader: showDialog message: $message');
      print('upgrader: showDialog releaseNotes: $releaseNotes');
    }

    // Save the date/time as the last time alerted.
    saveLastAlerted();

    Widget? dialogContent;

    if (content != null) {
      dialogContent = content(
        appName(),
        _appStoreVersion!,
        _installedVersion!,
        () {
          onUserUpdated(context, !blocked());
        },
      );
    }

    final route = DialogRoute(
      barrierDismissible: canDismissDialog,
      context: context,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      settings: const RouteSettings(name: 'upgrader_dialog'),
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () async => _shouldPopScope(),
            child: dialogContent ??
                _alertDialog(title ?? '', message, releaseNotes, context,
                    dialogStyle == UpgradeDialogStyle.cupertino));
      },
    );

    Navigator.of(context).push(route);

    _route = route;
    _context = context;
  }

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Defaults to false.
  bool _shouldPopScope() {
    if (debugLogging) {
      print('upgrader: onWillPop called');
    }
    if (shouldPopScope != null) {
      final should = shouldPopScope!();
      if (debugLogging) {
        print('upgrader: shouldPopScope=$should');
      }
      return should;
    }

    return false;
  }

  Widget _alertDialog(String title, String message, String? releaseNotes,
      BuildContext context, bool cupertino) {
    Widget? notes;
    if (releaseNotes != null) {
      notes = Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(messages.message(UpgraderMessage.releaseNotes) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(releaseNotes),
            ],
          ));
    }
    final textTitle = Text(title, key: const Key('upgrader.dialog.title'));
    final content = Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message),
            Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(messages.message(UpgraderMessage.prompt) ?? '')),
            if (notes != null) notes,
          ],
        )));
    final actions = <Widget>[
      if (showIgnore)
        _button(cupertino, messages.message(UpgraderMessage.buttonTitleIgnore),
            context, () => onUserIgnored(context, true)),
      if (showLater)
        _button(cupertino, messages.message(UpgraderMessage.buttonTitleLater),
            context, () => onUserLater(context, true)),
      _button(cupertino, messages.message(UpgraderMessage.buttonTitleUpdate),
          context, () => onUserUpdated(context, !blocked())),
    ];

    return cupertino
        ? CupertinoAlertDialog(
            title: textTitle, content: content, actions: actions)
        : AlertDialog(title: textTitle, content: content, actions: actions);
  }

  Widget _button(bool cupertino, String? text, BuildContext context,
      VoidCallback? onPressed) {
    return cupertino
        ? CupertinoDialogAction(
            textStyle: cupertinoButtonTextStyle,
            onPressed: onPressed,
            child: Text(text ?? ''))
        : TextButton(onPressed: onPressed, child: Text(text ?? ''));
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onIgnore != null) {
      doProcess = onIgnore!();
    }

    if (doProcess) {
      _saveIgnored();
    }

    if (shouldPop) {
      popNavigator(context: context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onLater != null) {
      doProcess = onLater!();
    }

    if (doProcess) {}

    if (shouldPop) {
      popNavigator(context: context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    var doProcess = true;
    if (onUpdate != null) {
      doProcess = onUpdate!();
    }

    if (doProcess) {
      _sendUserToAppStore();
    }

    if (shouldPop) {
      popNavigator(context: context);
    }
  }

  static Future<void> clearSavedSettings() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('userIgnoredVersion');
    await prefs.remove('lastTimeAlerted');
    await prefs.remove('lastVersionAlerted');

    return;
  }

  /// If the context is not passed, then the saved route and context values are used to removed the dialog from the pages stack.
  void popNavigator({BuildContext? context}) {
    if (context == null) {
      if (_route != null && _context != null) {
        Navigator.of(_context!).removeRoute(_route!);
        _route = null;
        _context = null;
        _displayed = false;
      }
      return;
    }
    Navigator.of(context).pop();
    _displayed = false;
  }

  Future<bool> _saveIgnored() async {
    var prefs = await SharedPreferences.getInstance();

    _userIgnoredVersion = _appStoreVersion;
    await prefs.setString('userIgnoredVersion', _userIgnoredVersion ?? '');
    return true;
  }

  Future<bool> saveLastAlerted() async {
    var prefs = await SharedPreferences.getInstance();
    _lastTimeAlerted = DateTime.now();
    await prefs.setString('lastTimeAlerted', _lastTimeAlerted.toString());

    _lastVersionAlerted = _appStoreVersion;
    await prefs.setString('lastVersionAlerted', _lastVersionAlerted ?? '');

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
    if (_appStoreListingURL == null || _appStoreListingURL!.isEmpty) {
      if (debugLogging) {
        print('upgrader: empty _appStoreListingURL');
      }
      return;
    }

    if (debugLogging) {
      print('upgrader: launching: $_appStoreListingURL');
    }

    try {
      await launchUrl(
        Uri.parse(_appStoreListingURL!),
        mode: upgraderOS.isAndroid
            ? LaunchMode.externalNonBrowserApplication
            : LaunchMode.platformDefault,
      );
    } catch (e) {
      if (debugLogging) {
        print('upgrader: launch to app store failed: $e');
      }
    }
  }
}
