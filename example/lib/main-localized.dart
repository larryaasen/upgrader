/*
 * Copyright (c) 2020 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

void main() => runApp(Demo());

class Demo extends StatelessWidget {
  Demo({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          DemoLocalizations.of(context).title,
      home: DemoApp(),
      localizationsDelegates: [
        const DemoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // English, no country code
        const Locale('es', ''), // Spanish, no country code
        const Locale('ar', ''), // Arabic, no country code
      ],
    );
  }
}

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Only call clearSavedSettings() during testing to reset internal values.
    Upgrader().clearSavedSettings();

    // On Android, setup the Appcast.
    // On iOS, the default behavior will be to use the App Store version of
    // the app, so update the Bundle Identifier in example/ios/Runner with a
    // valid identifier already in the App Store.
    final appcastURL =
        'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
    final cfg = AppcastConfiguration(url: appcastURL, supportedOS: ['android']);

    return Scaffold(
        appBar: AppBar(
          title: Text(DemoLocalizations.of(context).title),
        ),
        body: UpgradeAlert(
          appcastConfig: cfg,
          debugLogging: true,
          messages: MyUpgraderMessages(),
          child: Center(child: Text(DemoLocalizations.of(context).checking)),
        ));
  }
}

class DemoLocalizations {
  DemoLocalizations(this.locale);

  final Locale locale;

  static DemoLocalizations of(BuildContext context) {
    return Localizations.of<DemoLocalizations>(context, DemoLocalizations);
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'checking': 'Checking...',
      'title': 'Upgrader Localization Example',
    },
    'es': {
      'checking': 'Comprobando...',
      'title': 'Ejemplo Upgrader',
    },
  };

  String get checking {
    return _localizedValues[locale.languageCode]['checking'];
  }

  String get title {
    return _localizedValues[locale.languageCode]['title'];
  }
}

class DemoLocalizationsDelegate
    extends LocalizationsDelegate<DemoLocalizations> {
  const DemoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'es', 'ar'].contains(locale.languageCode);

  @override
  Future<DemoLocalizations> load(Locale locale) {
    return SynchronousFuture<DemoLocalizations>(DemoLocalizations(locale));
  }

  @override
  bool shouldReload(DemoLocalizationsDelegate old) => false;
}

/// Extend the [UpgraderMessages] class to provide custom values.
class MyUpgraderMessages extends UpgraderMessages {
  /// Override the [buttonTitleIgnore] getter to provide a custom value. Values
  /// provided in the [message] function will be used over this value.
  @override
  String get buttonTitleIgnore => 'My Ignore 1';

  /// Override the message function to provide your own language localization.
  @override
  String message(UpgraderMessage messageKey) {
    if (languageCode == 'es') {
      switch (messageKey) {
        case UpgraderMessage.body:
          return 'es A new version of {{appName}} is available!';
        case UpgraderMessage.buttonTitleIgnore:
          return 'es Ignore';
        case UpgraderMessage.buttonTitleLater:
          return 'es Later';
        case UpgraderMessage.buttonTitleUpdate:
          return 'es Update Now';
        case UpgraderMessage.prompt:
          return 'es Want to update?';
        case UpgraderMessage.title:
          return 'es Update App?';
      }
    }
    // Messages that are not provided above can still use the default values.
    return super.message(messageKey);
  }
}
