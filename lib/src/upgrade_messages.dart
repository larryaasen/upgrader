/*
 * Copyright (c) 2020-2022 Larry Aasen. All rights reserved.
 */

import 'dart:ui';

import 'package:flutter/material.dart';

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` to support older versions of the API as well.
T? ambiguate<T>(T? value) => value;

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

  /// Release Notes
  releaseNotes,

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
  UpgraderMessages({String? code})
      : languageCode = (code ?? findLanguageCode()) {
    assert(languageCode.isNotEmpty);
  }

  /// Override the message function to provide custom language localization.
  String? message(UpgraderMessage messageKey) {
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
      case UpgraderMessage.releaseNotes:
        return releaseNotes;
      case UpgraderMessage.title:
        return title;
      default:
    }
    return null;
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device.
  static String findLanguageCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    } else {
      // Get the system locale
      locale = PlatformDispatcher.instance.locale;
    }
    final code = locale == null || locale.languageCode.isEmpty
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
  ///
  String get body => switch (languageCode) {
        'ar' =>
          'نسخة جديدة من {{appName}} متوفرة! النسخة {{currentAppStoreVersion}} متوفرة الآن, أنت تستخدم النسخة {{currentInstalledVersion}}.',
        'bn' =>
          '{{appName}} এর একটি নতুন সংস্করণ {{currentAppStoreVersion}} পাওয়া যাচ্ছে। আপনার অ্যাপলিকেশনের সংস্করণ হচ্ছে {{currentInstalledVersion}}।',
        'da' =>
          'En ny version af {{appName}} er tilgængelig! Version {{currentAppStoreVersion}} er nu tilgængelig - du har {{currentInstalledVersion}}.',
        'el' =>
          'Μια νέα έκδοση του {{appName}} είναι διαθέσιμη! Η έκδοση {{currentAppStoreVersion}} είναι διαθέσιμη-έχετε την {{currentInstalledVersion}}.',
        'es' =>
          '¡Una nueva versión de {{appName}} está disponible! La versión {{currentAppStoreVersion}} ya está disponible-usted tiene {{currentInstalledVersion}}.',
        'fa' =>
          'نسخه‌ی جدیدی از {{appName}} موجود است! نسخه‌ی {{currentAppStoreVersion}} در دسترس است ولی شما همچنان از نسخه‌ی {{currentInstalledVersion}} استفاده می‌کنید.',
        'fil' =>
          'May bagong bersyon ang {{appName}} na pwede nang magamit! Ang bersyong {{currentAppStoreVersion}} ay pwede nang magamit. Ikaw ay kasalukuyang gumagamit ng bersyong {{currentInstalledVersion}}.',
        'fr' =>
          'Une nouvelle version de {{appName}} est disponible ! La version {{currentAppStoreVersion}} est maintenant disponible, vous avez la version {{currentInstalledVersion}}.',
        'de' =>
          'Eine neue Version von {{appName}} ist verfügbar! Die Version {{currentAppStoreVersion}} ist verfügbar, installiert ist die Version {{currentInstalledVersion}}.',
        'he' =>
          'גרסה חדשה של {{appName}} קיימת! גרסה {{currentAppStoreVersion}} ניתנת להורדה-יש לך גרסה {{currentInstalledVersion}}.',
        'hi' =>
          '{app name} का एक नया संस्करण उपलब्ध है। संस्करण {{currentAppStoreVersion}} अब उपलब्ध है-आपके पास है {{currentInstalledVersion}}.',
        'ht' =>
          'Yon nouvo vèsyon {{appName}} disponib! Vèsyon {{currentAppStoreVersion}} disponib, epi ou gen vèsyon {{currentInstalledVersion}}.',
        'hu' =>
          'Új verzió érhető el az alkalmazásból {{appName}} ! Az elérhető új verzió: {{currentAppStoreVersion}} - a jelenlegi verzió: {{currentInstalledVersion}}.',
        'id' =>
          'Versi terbaru dari {{appName}} tersedia! Versi terbaru saat ini adalah {{currentAppStoreVersion}} - versi anda saat ini adalah {{currentInstalledVersion}}.',
        'it' =>
          'Una nuova versione di {{appName}} è disponibile! La versione {{currentAppStoreVersion}} è ora disponibile, voi avete {{currentInstalledVersion}}.',
        'ja' =>
          '現在のバージョンは、{{currentInstalledVersion}}です。{{appName}}の最新バージョン({{currentAppStoreVersion}})があります。',
        'kk' =>
          '{{appName}} қосымша жаңа нұсқасын жүктеп алыңыз! Жаңа нұсқасы: {{currentAppStoreVersion}}, қазіргі нұсқасы: {{currentInstalledVersion}}',
        'km' =>
          'មានការអាប់ដេតថ្មីកម្មវិធី {{appName}} ហើយ! កំណែអាប់ដែត {{currentAppStoreVersion}} គឺអាចប្រើប្រាប់បានជំនួស {{currentInstalledVersion}} បានហើយ។',
        'ko' =>
          '{{appName}}이 새 버전으로 업데이트되었습니다! 최신 버전 {{currentAppStoreVersion}}으로 업그레이드 가능합니다 - 현재 버전 {{currentInstalledVersion}}.',
        'lt' =>
          'Išleista nauja programos {{appName}} versija! Versija {{currentAppStoreVersion}} yra prieinama, jūs turite {{currentInstalledVersion}}.',
        'mn' =>
          '{{appName}}-н шинэ хувилбар бэлэн боллоо! Таны одоогийн ашиглаж буй хувилбар {{currentInstalledVersion}} - Шинээр бэлэн болсон хувилбар нь {{currentAppStoreVersion}} юм .',
        'nb' =>
          'En ny versjon av {{appName}} er tilgjengelig! {{currentAppStoreVersion}} er nå tilgjengelig - du har {{currentInstalledVersion}}.',
        'nl' =>
          'Er is een nieuwe versie van {{appName}} beschikbaar! De nieuwe versie is {{currentAppStoreVersion}}, je gebruikt nu versie {{currentInstalledVersion}}.',
        'pt' =>
          'Há uma nova versão do {{appName}} disponível! A versão {{currentAppStoreVersion}} já está disponível, você tem a {{currentInstalledVersion}}.',
        'pl' =>
          'Nowa wersja {{appName}} jest dostępna! Wersja {{currentAppStoreVersion}} jest dostępna, Ty masz {{currentInstalledVersion}}.',
        'ru' =>
          'Доступна новая версия приложения {{appName}}! Новая версия: {{currentAppStoreVersion}}, текущая версия: {{currentInstalledVersion}}.',
        'sv' =>
          'En ny version av {{appName}} är tillgänglig! Version {{currentAppStoreVersion}} är tillgänglig - du har {{currentInstalledVersion}}.',
        'ta' =>
          '{{appName}}-ன் புதிய பதிப்பு {{currentAppStoreVersion}} இப்போது கிடைக்கிறது! உங்களிடம் {{currentInstalledVersion}} உள்ளது.',
        'te' =>
          '{{appName}} యాప్ యొక్క కొత్త వెర్షన్ అందుబాటులో ఉంది. వెర్షన్ {{currentAppStoreVersion}} అందుబాటులో ఉంది కానీ మీ దగ్గర {{currentInstalledVersion}} ఉంది.',
        'tr' =>
          '{{appName}} uygulamanızın yeni bir versiyonu mevcut! Versiyon {{currentAppStoreVersion}} şu anda erişilebilir, mevcut sürümünüz {{currentInstalledVersion}}.',
        'uk' =>
          'Доступна нова версія додатка {{appName}}! Нова версія: {{currentAppStoreVersion}}, поточна версія: {{currentInstalledVersion}}.',
        'vi' =>
          'Đã có phiên bản mới của {{appName}}. Phiên bản {{currentAppStoreVersion}} đã sẵn sàng, bạn đang dùng {{currentInstalledVersion}}.',
        'zh' =>
          '{{appName}}有新的版本！您拥有{{currentInstalledVersion}}的版本可更新到{{currentAppStoreVersion}}的版本。',
        'en' ||
        _ =>
          'A new version of {{appName}} is available! Version {{currentAppStoreVersion}} is now available-you have {{currentInstalledVersion}}.',
      };

  /// The ignore button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleIgnore => switch (languageCode) {
        'ar' => 'تجاهل',
        'bn' => 'বাতিল',
        'da' => 'IGNORER',
        'el' => 'ΑΓΝΟΗΣTΕ',
        'es' => 'IGNORAR',
        'fa' => 'ردکردن',
        'fil' => 'HUWAG PANSININ',
        'fr' => 'IGNORER',
        'de' => 'IGNORIEREN',
        'he' => 'התעלם',
        'hi' => 'नज़रअंदाज़ करना',
        'ht' => 'IGNORE',
        'hu' => 'KIHAGYOM',
        'id' => 'ABAIKAN',
        'it' => 'IGNORA',
        'ja' => '今はしない',
        'kk' => 'ЖОҚ',
        'km' => 'មិនអើពើ',
        'ko' => '무시',
        'lt' => 'IGNORUOTI',
        'mn' => 'Татгалзах',
        'nb' => 'IGNORER',
        'nl' => 'NEGEREN',
        'pt' => 'IGNORAR',
        'pl' => 'IGNORUJ',
        'ru' => 'НЕТ',
        'sv' => 'AVBRYT',
        'ta' => 'புறக்கணி',
        'te' => 'తిరస్కరించండి',
        'tr' => 'YOKSAY',
        'uk' => 'НІ',
        'vi' => 'BỎ QUA',
        'zh' => '不理',
        'en' || _ => 'IGNORE',
      };

  /// The later button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleLater => switch (languageCode) {
        'ar' =>
          //only minor change here, removing the character at the left top of the arabic word (لاحقاً)
          // before: message = 'لاحقاً';
          //now:
          'لاحقا',
        'bn' => 'পরে',
        'da' => 'SENERE',
        'el' => 'ΑΡΓΟΤΕΡΑ',
        'es' => 'MÁS TARDE',
        'fa' => 'بعدا',
        'fil' => 'MAMAYA',
        'fr' => 'PLUS TARD',
        'de' => 'SPÄTER',
        'he' => 'אחר-כך',
        'hi' => 'बाद में',
        'ht' => 'PITA',
        'hu' => 'KÉSŐBB',
        'id' => 'NANTI',
        'it' => 'DOPO',
        'ja' => '後で通知',
        'kk' => 'КЕЙІН',
        'km' => 'ពេលក្រោយ',
        'ko' => '나중에',
        'lt' => 'ATNAUJINTI VĖLIAU',
        'mn' => 'Дараа суулгах',
        'nb' => 'SENERE',
        'nl' => 'LATER',
        'pt' => 'MAIS TARDE',
        'pl' => 'PÓŹNIEJ',
        'ru' => 'ПОЗЖЕ',
        'sv' => 'SENARE',
        'ta' => 'பிறகு',
        'te' => 'తరువాత',
        'tr' => 'SONRA',
        'uk' => 'ПІЗНІШЕ',
        'vi' => 'ĐỂ SAU',
        'zh' => '以后',
        'en' || _ => 'LATER',
      };

  /// The update button title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get buttonTitleUpdate => switch (languageCode) {
        'ar' => 'حدث الآن',
        'bn' => 'এখন আপডেট করুন',
        'da' => 'OPDATER NU',
        'el' => 'ΕΝΗΜΕΡΩΣΗ',
        'es' => 'ACTUALIZAR',
        'fa' => 'بروزرسانی',
        'fil' => 'I-UPDATE NA NGAYON',
        'fr' => 'MAINTENANT',
        'de' => 'AKTUALISIEREN',
        'he' => 'עדכן',
        'hi' => 'अभी अद्यतन करें',
        'ht' => 'MIZAJOU KOUNYE A',
        'hu' => 'FRISSÍTSE MOST',
        'id' => 'PERBARUI SEKARANG',
        'it' => 'AGGIORNA ORA',
        'ja' => 'アップデート',
        'kk' => 'ЖАҢАРТУ',
        'km' => 'អាប់ដេតឥឡូវនេះ',
        'ko' => '지금 업데이트',
        'lt' => 'ATNAUJINTI DABAR',
        'mn' => 'Шинэчлэх',
        'nb' => 'OPPDATER NÅ',
        'nl' => 'NU UPDATEN',
        'pt' => 'ATUALIZAR',
        'pl' => 'AKTUALIZUJ',
        'ru' => 'ОБНОВИТЬ',
        'sv' => 'UPPDATERA NU',
        'ta' => 'இப்பொழுது புதுப்பிக்கவும்',
        'te' => 'అప్‌డేట్‌ చేయండి',
        'tr' => 'ŞİMDİ GÜNCELLE',
        'uk' => 'ОНОВИТИ',
        'vi' => 'CẬP NHẬT',
        'zh' => '更新',
        'en' || _ => 'UPDATE NOW',
      };

  /// The call to action prompt message.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get prompt => switch (languageCode) {
        'ar' => 'هل تفضل أن يتم التحديث الآن',
        'bn' => 'আপনি কি এখনই এটি আপডেট করতে চান?',
        'da' => 'Vil du opdatere nu?',
        'el' => 'Θέλετε να κάνετε την ενημέρωση τώρα,',
        'es' => '¿Le gustaría actualizar ahora?',
        'fa' => 'آیا بروزرسانی می‌کنید؟',
        'fil' => 'Gusto mo bang i-update ito ngayon?',
        'fr' => 'Voulez-vous mettre à jour maintenant ?',
        'de' => 'Möchtest du jetzt aktualisieren?',
        'he' => 'האם תרצה לעדכן עכשיו?',
        'hi' => 'क्या आप इसे अभी अद्यतन करना चाहेंगे?',
        'ht' => 'Èske ou vle mete ajou aplikasyon an kounye a?',
        'hu' => 'Akarja most frissíteni?',
        'id' => 'Apakah Anda ingin memperbaruinya sekarang?',
        'it' => 'Ti piacerebbe aggiornare ora?',
        'ja' => '今すぐアップデートしますか?',
        'kk' => 'Қазір жаңартқыңыз келе ме?',
        'km' => 'តើអ្នកចង់អាប់ដេតវាឥឡូវនេះទេ?',
        'ko' => '지금 업데이트를 시작하시겠습니까?',
        'lt' => 'Ar norite atnaujinti dabar?',
        'mn' => 'Та одоо шинэчлэлтийг татаж авах уу?',
        'nb' => 'Ønsker du å oppdatere nå?',
        'nl' => 'Wil je de app nu updaten?',
        'pt' => 'Você quer atualizar agora?',
        'pl' => 'Czy chciałbyś zaktualizować teraz?',
        'ru' => 'Хотите обновить сейчас?',
        'sv' => 'Vill du uppdatera nu?',
        'ta' => 'இப்போது புதுப்பிக்க விரும்புகிறீர்களா?',
        'te' => 'మీరు దీన్ని ఇప్పుడే అప్‌డేట్ చేయాలనుకుంటున్నారా?',
        'tr' => 'Şimdi güncellemek ister misiniz?',
        'uk' => 'Бажаєте оновити зараз?',
        'vi' => 'Bạn có muốn cập nhật ứng dụng?',
        'zh' => '您现在要更新应用程序吗？',
        'en' || _ => 'Would you like to update it now?',
      };

  /// The release notes message.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get releaseNotes => switch (languageCode) {
        'ar' => 'تفاصيل الاصدار',
        'da' => 'Udgivelsesnoter',
        'de' => 'Versionshinweise',
        'es' => 'Notas De Lanzamiento',
        'fr' => 'Notes de version',
        'he' => 'חדש בגרסה',
        'hi' => 'रिहाई टिप्पणी',
        'id' => 'Catatan Rilis',
        'it' => 'Note di rilascio',
        'ja' => 'リリースノート',
        'pt' => 'Novidades',
        'ru' => 'Информация о выпуске',
        'te' => 'విడుదల గమనికలు',
        'tr' => 'Yayın Notları',
        'bn' ||
        'el' ||
        'fa' ||
        'fil' ||
        'ht' ||
        'hu' ||
        'kk' ||
        'km' ||
        'ko' ||
        'lt' ||
        'mn' ||
        'nb' ||
        'nl' ||
        'pl' ||
        'sv' ||
        'ta' ||
        'uk' ||
        'vi' ||
        'zh' ||
        'en' ||
        _ =>
          'Release Notes',
      };

  /// The alert dialog title.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get title => switch (languageCode) {
        'ar' => 'هل تريد تحديث التطبيق؟',
        'bn' => 'আপডেট অ্যাপ্লিকেশন?',
        'da' => 'Opdater App?',
        'el' => 'Ενημέρωση εφαρμογής,',
        'es' => '¿Actualizar la aplicación?',
        'fa' => 'نسخه‌ی جدید',
        'fil' => 'I-update ang app?',
        'fr' => 'Mettre à jour l\'application ?',
        'de' => 'App aktualisieren?',
        'he' => 'לעדכן יישומון?',
        'hi' => 'अद्यतन ऐप?',
        'ht' => 'Mete ajou app a?',
        'hu' => 'FrissÍtés?',
        'id' => 'Perbarui Aplikasi?',
        'it' => 'Aggiornare l\'applicazione?',
        'ja' => 'アプリのアップデート',
        'kk' => 'Жаңарту керек пе?',
        'km' => 'អាប់ដេតកម្មវិធីទេ?',
        'ko' => '앱을 업데이트하시겠습니까?',
        'lt' => 'Atnaujinti programą?',
        'mn' => 'Та шинэчлэлт хийх үү?',
        'nb' => 'Oppdater app?',
        'nl' => 'App updaten?',
        'pt' => 'Atualizar aplicação?',
        'pl' => 'Czy zaktualizować aplikację?',
        'ru' => 'Обновить?',
        'sv' => 'Uppdatera App?',
        'ta' => 'செயலியை புதுப்பிக்கவா?',
        'te' => 'యాప్‌ని అప్‌డేట్‌ చేయాలా?',
        'tr' => 'Uygulamayı Güncelle?',
        'uk' => 'Оновити?',
        'vi' => 'Cập nhật ứng dụng?',
        'zh' => '更新应用程序？',
        'en' || _ => 'Update App?',
      };
}
