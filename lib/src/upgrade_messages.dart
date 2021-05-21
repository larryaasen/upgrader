/*
 * Copyright (c) 2020 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';

/// The message identifiers used in upgrader.
enum UpgraderMessage {
  /// Body of the upgrade message
  body,

  /// Ignore button
  buttonTitleIgnore,

  /// Later button
  buttonTitleLater,

  /// Update Now button
  buttonTitleUpdate,

  /// Prompt message
  prompt,

  /// Title
  title,
}

/// The default localized messages used for display in upgrader. Extend this
/// class to provide custom values and new localizations for languages.
/// An example to replace the Ignore button with a custom value would be:
///
/// ```dart
/// class MyUpgraderMessages extends UpgraderMessages {
///   @override
///   String get buttonTitleIgnore => 'My Ignore';
/// }
///
/// UpgradeAlert(messages: MyUpgraderMessages());
/// ```
///
class UpgraderMessages {
  /// The primary language subtag for the locale, which defaults to the
  /// system-reported default locale of the device.
  final String languageCode;

  /// Provide a [code] to override the system-reported default locale.
  UpgraderMessages({String code}) : languageCode = code ?? findLanguageCode() {
    assert(languageCode != null && languageCode.isNotEmpty);
  }

  /// Override the message function to provide custom language localization.
  String message(UpgraderMessage messageKey) {
    switch (messageKey) {
      case UpgraderMessage.body:
        return body;
      case UpgraderMessage.buttonTitleIgnore:
        return buttonTitleIgnore;
      case UpgraderMessage.buttonTitleLater:
        return buttonTitleLater;
      case UpgraderMessage.buttonTitleUpdate:
        return buttonTitleUpdate;
      case UpgraderMessage.prompt:
        return prompt;
      case UpgraderMessage.title:
        return title;
      default:
    }
    return null;
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device.
  static String findLanguageCode({BuildContext context}) {
    Locale locale;
    if (context != null) {
      locale = Localizations.localeOf(context);
    } else {
      // Get the system locale
      locale = WidgetsBinding.instance.window.locale;
    }
    final code = locale == null ||
            locale.languageCode == null ||
            locale.languageCode.isEmpty
        ? 'en'
        : locale.languageCode;
    return code;
  }

  /// The body of the upgrade message. This string supports mustache style
  /// template variables:
  ///   {{appName}}
  ///   {{currentAppStoreVersion}}
  ///   {{currentInstalledVersion}}
  /// Example:
  ///  'A new version of Upgrader is available! Version 1.2 is now available-you have 1.0.';

  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get body {
    String message;
    switch (languageCode) {
      case 'ar':
        message =
            'نسخة جديدة من {{appName}} متوفرة! النسخة {{currentAppStoreVersion}} متوفرة الآن, أنت تستخدم النسخة {{currentInstalledVersion}}.';
        break;
      case 'es':
        message =
            '¡Una nueva versión de {{appName}} está disponible! La versión {{currentAppStoreVersion}} ya está disponible-usted tiene {{currentInstalledVersion}}.';
        break;
      case 'fr':
        message =
            'Une nouvelle version de {{appName}} est disponible ! La version {{currentAppStoreVersion}} est maintenant disponible, vous avez la version {{currentInstalledVersion}}.';
        break;
      case 'de':
        message =
            'Eine neue Version von {{appName}} ist verfügbar! Die Version {{currentAppStoreVersion}} ist verfügbar, installiert ist die Version {{currentInstalledVersion}}.';
        break;
      case 'hu':
        message =
            'Új verzió érhető el az alkalmazásból {{appName}} ! Az elérhető új verzió: {{currentAppStoreVersion}} - a jelenlegi verzió: {{currentInstalledVersion}}.';
        break;
      case 'id':
        message =
            'Versi terbaru dari {{appName}} tersedia! Versi terbaru saat ini adalah {{currentAppStoreVersion}} - versi anda saat ini adalah {{currentInstalledVersion}}.';
        break;
      case 'it':
        message =
            'Una nuova versione di {{appName}} è disponibile! La versione {{currentAppStoreVersion}} è ora disponibile, voi avete {{currentInstalledVersion}}.';
        break;
      case 'ko':
        message =
            '{{appName}}이 새 버전으로 업데이트되었습니다! 최신 버전 {{currentAppStoreVersion}}으로 업그레이드 가능합니다 - 현재 버전 {{currentInstalledVersion}}.';
        break;
      case 'pt':
        message =
            'Há uma nova versão do {{appName}} disponível! A versão {{currentAppStoreVersion}} já está disponível, você tem a {{currentInstalledVersion}}.';
        break;
      case 'pl':
        message =
            'Nowa wersja {{appName}} jest dostępna! Wersja {{currentAppStoreVersion}} jest dostępna, Ty masz {{currentInstalledVersion}}.';
        break;
      case 'ru':
        message =
            'Доступна новая версия приложения {{appName}}! Новая версия: {{currentAppStoreVersion}}, текущая версия: {{currentInstalledVersion}}.';
        break;
      case 'tr':
        message =
            '{{appName}} uygulamanızın yeni bir versiyonu mevcut! Versiyon {{currentAppStoreVersion}} şu anda erişilebilir, mevcut sürümünüz {{currentInstalledVersion}}.';
        break;
      case 'vi':
        message =
            'Đã có phiên bản mới của {{appName}}. Phiên bản {{currentAppStoreVersion}} đã sẵn sàng, bạn đang dùng {{currentInstalledVersion}}.';
        break;
      case 'en':
      default:
        message =
            'A new version of {{appName}} is available! Version {{currentAppStoreVersion}} is now available-you have {{currentInstalledVersion}}.';
        break;
    }
    return message;
  }

  /// The ignore button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleIgnore {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'تجاهل';
        break;
      case 'es':
        message = 'IGNORAR';
        break;
      case 'fr':
        message = 'IGNORER';
        break;
      case 'de':
        message = 'IGNORIEREN';
        break;
      case 'hu':
        message = 'KIHAGYOM';
        break;
      case 'id':
        message = 'ABAIKAN';
        break;
      case 'it':
        message = 'IGNORA';
        break;
      case 'ko':
        message = '무시';
        break;
      case 'pt':
        message = 'IGNORAR';
        break;
      case 'pl':
        message = 'IGNORUJ';
        break;
      case 'ru':
        message = 'НЕТ';
        break;
      case 'tr':
        message = 'YOKSAY';
        break;
      case 'vi':
        message = 'BỎ QUA';
        break;
      case 'en':
      default:
        message = 'IGNORE';
        break;
    }
    return message;
  }

  /// The later button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleLater {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'لاحقاً';
        break;
      case 'es':
        message = 'MÁS TARDE';
        break;
      case 'fr':
        message = 'PLUS TARD';
        break;
      case 'de':
        message = 'SPÄTER';
        break;
      case 'hu':
        message = 'KÉSŐBB';
        break;
      case 'id':
        message = 'NANTI';
        break;
      case 'it':
        message = 'DOPO';
        break;
      case 'ko':
        message = '나중에';
        break;
      case 'pt':
        message = 'MAIS TARDE';
        break;
      case 'pl':
        message = 'PÓŹNIEJ';
        break;
      case 'ru':
        message = 'ПОЗЖЕ';
        break;
      case 'tr':
        message = 'SONRA';
        break;
      case 'vi':
        message = 'ĐỂ SAU';
        break;
      case 'en':
      default:
        message = 'LATER';
        break;
    }
    return message;
  }

  /// The update button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleUpdate {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'حدث الآن';
        break;
      case 'es':
        message = 'ACTUALIZAR';
        break;
      case 'fr':
        message = 'MAINTENANT';
        break;
      case 'de':
        message = 'AKTUALISIEREN';
        break;
      case 'hu':
        message = 'FRISSÍTSE MOST';
        break;
      case 'id':
        message = 'PERBARUI SEKARANG';
        break;
      case 'it':
        message = 'AGGIORNA ORA';
        break;
      case 'ko':
        message = '지금 업데이트';
        break;
      case 'pt':
        message = 'ATUALIZAR';
        break;
      case 'pl':
        message = 'AKTUALIZUJ';
        break;
      case 'ru':
        message = 'ОБНОВИТЬ';
        break;
      case 'tr':
        message = 'ŞİMDİ GÜNCELLE';
        break;
      case 'vi':
        message = 'CẬP NHẬT';
        break;
      case 'en':
      default:
        message = 'UPDATE NOW';
        break;
    }
    return message;
  }

  /// The call to action prompt message.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get prompt {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'هل تفضل أن يتم التحديث الآن';
        break;
      case 'es':
        message = '¿Le gustaría actualizar ahora?';
        break;
      case 'fr':
        message = 'Voulez-vous mettre à jour maintenant?';
        break;
      case 'de':
        message = 'Möchtest du jetzt aktualisieren?';
        break;
      case 'hu':
        message = 'Akarja most frissíteni?';
        break;
      case 'id':
        message = 'Apakah Anda ingin memperbaruinya sekarang?';
        break;
      case 'it':
        message = 'Ti piacerebbe aggiornare ora?';
        break;
      case 'ko':
        message = '지금 업데이트를 시작하시겠습니까?';
        break;
      case 'pt':
        message = 'Você quer atualizar agora?';
        break;
      case 'pl':
        message = 'Czy chciałbyś zaktualizować teraz?';
        break;
      case 'ru':
        message = 'Хотите обновить сейчас?';
        break;
      case 'tr':
        message = 'Şimdi güncellemek ister misiniz?';
        break;
      case 'vi':
        message = 'Bạn có muốn cập nhật ứng dụng?';
        break;
      case 'en':
      default:
        message = 'Would you like to update it now?';
        break;
    }
    return message;
  }

  /// The alert dialog title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get title {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'هل تريد تحديث التطبيق؟';
        break;
      case 'es':
        message = '¿Actualizar la aplicación?';
        break;
      case 'fr':
        message = 'Mettre à jour l\'application?';
        break;
      case 'de':
        message = 'App aktualisieren?';
        break;
      case 'hu':
        message = 'FrissÍtés?';
        break;
      case 'id':
        message = 'Perbarui Aplikasi?';
        break;
      case 'it':
        message = 'Aggiornare l\'applicazione?';
        break;
      case 'ko':
        message = '앱을 업데이트하시겠습니까?';
        break;
      case 'pt':
        message = 'Atualizar aplicação?';
        break;
      case 'pl':
        message = 'Czy zaktualizować aplikację?';
        break;
      case 'ru':
        message = 'Обновить?';
        break;
      case 'tr':
        message = 'Uygulamayı Güncelle?';
        break;
      case 'vi':
        message = 'Cập nhật ứng dụng?';
        break;
      case 'en':
      default:
        message = 'Update App?';
        break;
    }
    return message;
  }
}
