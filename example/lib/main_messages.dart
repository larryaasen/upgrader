/*
 * Copyright (c) 2020-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) =>
          DemoLocalizations.of(context).title,
      home: DemoApp(),
      localizationsDelegates: const [
        DemoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English, no country code
        Locale('ar', ''), // Arabic, no country code
        Locale('bn', ''), // Bengali, no country code
        Locale('da', ''), // Danish, no country code
        Locale('es', ''), // Spanish, no country code
        Locale('fa', ''), // Persian, no country code
        Locale('fil', ''), // Filipino, no country code
        Locale('fr', ''), // French, no country code
        Locale('de', ''), // German, no country code
        Locale('el', ''), // Greek, no country code
        Locale('he', ''), // Hebrew, no country code
        Locale('hi', ''), // Hindi, no country code
        Locale('ht', ''), // Haitian Creole, no country code
        Locale('hu', ''), // Hungarian, no country code
        Locale('id', ''), // Indonesian, no country code
        Locale('it', ''), // Italian, no country code
        Locale('ja', ''), // Japanese, no country code
        Locale('kk', ''), // Kazakh, no country code
        Locale('km', ''), // Khmer, no country code
        Locale('ko', ''), // Korean, no country code
        Locale('ku', ''), // Kurdish Sorani, no country code
        Locale('lt', ''), // Lithuanian, no country code
        Locale('mn', ''), // Mongolian, no country code
        Locale('nb', ''), // Norwegian, no country code
        Locale('nl', ''), // Dutch, no country code
        Locale('pt', ''), // Portuguese, no country code
        Locale('pl', ''), // Polish, no country code
        Locale('ps', ''), // Pashto, no country code
        Locale('ru', ''), // Russian, no country code
        Locale('sv', ''), // Swedish, no country code
        Locale('ta', ''), // Tamil, no country code
        Locale('te', ''), // Telugu, no country code
        Locale('tr', ''), // Turkish, no country code
        Locale('uk', ''), // Ukrainian, no country code
        Locale('vi', ''), // Vietnamese, no country code
        Locale('zh', ''), // Chinese, no country code
      ],
    );
  }
}

class DemoApp extends StatelessWidget {
  static const appcastURL =
      'https://raw.githubusercontent.com/larryaasen/upgrader/master/test/testappcast.xml';
  final upgrader = Upgrader(
    storeController: UpgraderStoreController(
        onAndroid: () => UpgraderAppcastStore(appcastURL: appcastURL)),
    debugLogging: true,
    messages: MyUpgraderMessages(code: 'es'),
  );

  DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(DemoLocalizations.of(context).title)),
        body: UpgradeAlert(
          upgrader: upgrader,
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
        'ku',
        'lt',
        'mn',
        'nb',
        'nl',
        'pt',
        'pl',
        'ps',
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

  MyUpgraderMessages({super.code});

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
