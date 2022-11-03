/*
 * Copyright (c) 2020-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, setup the Appcast.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(Demo());
}

class Demo extends StatelessWidget {
  Demo({Key? key}) : super(key: key);

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
        const Locale('ar', ''), // Arabic, no country code
        const Locale('bn', ''), // Bengali, no country code
        const Locale('da', ''), // Danish, no country code
        const Locale('es', ''), // Spanish, no country code
        const Locale('fa', ''), // Persian, no country code
        const Locale('fil', ''), // Filipino, no country code
        const Locale('fr', ''), // French, no country code
        const Locale('de', ''), // German, no country code
        const Locale('el', ''), // Greek, no country code
        const Locale('he', ''), // Hebrew, no country code
        const Locale('hi', ''), // Hindi, no country code
        const Locale('ht', ''), // Haitian Creole, no country code
        const Locale('hu', ''), // Hungarian, no country code
        const Locale('id', ''), // Indonesian, no country code
        const Locale('it', ''), // Italian, no country code
        const Locale('ja', ''), // Japanese, no country code
        const Locale('kk', ''), // Kazakh, no country code
        const Locale('km', ''), // Khmer, no country code
        const Locale('ko', ''), // Korean, no country code
        const Locale('lt', ''), // Lithuanian, no country code
        const Locale('mn', ''), // Mongolian, no country code
        const Locale('nb', ''), // Norwegian, no country code
        const Locale('nl', ''), // Dutch, no country code
        const Locale('pt', ''), // Portuguese, no country code
        const Locale('pl', ''), // Polish, no country code
        const Locale('ru', ''), // Russian, no country code
        const Locale('sv', ''), // Swedish, no country code
        const Locale('ta', ''), // Tamil, no country code
        const Locale('te', ''), // Telugu, no country code
        const Locale('tr', ''), // Turkish, no country code
        const Locale('uk', ''), // Ukrainian, no country code
        const Locale('vi', ''), // Vietnamese, no country code
        const Locale('zh', ''), // Chinese, no country code
      ],
    );
  }
}

class DemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appcastURL =
        'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
    final cfg = AppcastConfiguration(url: appcastURL, supportedOS: ['android']);

    return Scaffold(
        appBar: AppBar(title: Text(DemoLocalizations.of(context).title)),
        body: UpgradeAlert(
          upgrader: Upgrader(
            appcastConfig: cfg,
            debugLogging: true,
            messages: MyUpgraderMessages(code: 'es'),
          ),
          child: Center(child: Text(DemoLocalizations.of(context).checking)),
        ));
  }
}

class DemoLocalizations {
  DemoLocalizations(this.locale);

  final Locale locale;

  static DemoLocalizations of(BuildContext context) {
    return Localizations.of<DemoLocalizations>(context, DemoLocalizations)!;
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
    return _localizedValues[locale.languageCode]!['checking']!;
  }

  String get title {
    return _localizedValues[locale.languageCode]!['title']!;
  }
}

class DemoLocalizationsDelegate
    extends LocalizationsDelegate<DemoLocalizations> {
  const DemoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => [
        'en',
        'ar',
        'bn',
        'da',
        'es',
        'fa',
        'fil',
        'fr',
        'de',
        'el',
        'he',
        'hi',
        'ht',
        'hu',
        'id',
        'it',
        'ja',
        'kk',
        'km',
        'ko',
        'lt',
        'mn',
        'nb',
        'nl',
        'pt',
        'pl',
        'ru',
        'sv',
        'ta',
        'te',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

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

  MyUpgraderMessages({String? code}) : super(code: code);

  /// Override the message function to provide your own language localization.
  @override
  String? message(UpgraderMessage messageKey) {
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
        case UpgraderMessage.releaseNotes:
          return 'es Release Notes';
        case UpgraderMessage.title:
          return 'es Update App?';
      }
    }
    // Messages that are not provided above can still use the default values.
    return super.message(messageKey);
  }
}
