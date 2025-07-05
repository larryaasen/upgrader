// Copyright (c) 2020-2024 Larry Aasen. All rights reserved.

import 'dart:ui';

import 'package:flutter/widgets.dart';

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` to support older versions of the API as w ell.
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
/// final upgrader = Upgrader(messages: MyUpgraderMessages());
/// ...
/// UpgradeAlert(upgrader: upgrader);
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
    }
  }

  /// Determine the current language code, either from the context, or
  /// from the system-reported default locale of the device.
  static String findLanguageCode({BuildContext? context}) {
    Locale? locale;
    if (context != null) {
      locale = Localizations.maybeLocaleOf(context);
    }
    // Get the system locale
    locale ??= PlatformDispatcher.instance.locale;

    final code = locale.languageCode.isEmpty ? 'en' : locale.languageCode;
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
      case 'bn':
        message =
            '{{appName}} এর একটি নতুন সংস্করণ {{currentAppStoreVersion}} পাওয়া যাচ্ছে। আপনার অ্যাপলিকেশনের সংস্করণ হচ্ছে {{currentInstalledVersion}}।';
        break;
      case 'da':
        message =
            'En ny version af {{appName}} er tilgængelig! Version {{currentAppStoreVersion}} er nu tilgængelig - du har {{currentInstalledVersion}}.';
        break;
      case 'el':
        message =
            'Μια νέα έκδοση του {{appName}} είναι διαθέσιμη! Η έκδοση {{currentAppStoreVersion}} είναι διαθέσιμη-έχετε την {{currentInstalledVersion}}.';
        break;
      case 'es':
        message =
            '¡Una nueva versión de {{appName}} está disponible! La versión {{currentAppStoreVersion}} ya está disponible-usted tiene {{currentInstalledVersion}}.';
        break;
      case 'fa':
        message =
            'نسخه‌ی جدیدی از {{appName}} موجود است! نسخه‌ی {{currentAppStoreVersion}} در دسترس است ولی شما همچنان از نسخه‌ی {{currentInstalledVersion}} استفاده می‌کنید.';
        break;
      case 'fil':
        message =
            'May bagong bersyon ang {{appName}} na pwede nang magamit! Ang bersyong {{currentAppStoreVersion}} ay pwede nang magamit. Ikaw ay kasalukuyang gumagamit ng bersyong {{currentInstalledVersion}}.';
        break;
      case 'fr':
        message =
            'Une nouvelle version de {{appName}} est disponible ! La version {{currentAppStoreVersion}} est maintenant disponible, vous avez la version {{currentInstalledVersion}}.';
        break;
      case 'de':
        message =
            'Eine neue Version von {{appName}} ist verfügbar! Die Version {{currentAppStoreVersion}} ist verfügbar, installiert ist die Version {{currentInstalledVersion}}.';
        break;
      case 'he':
        message =
            'גרסה חדשה של {{appName}} קיימת! גרסה {{currentAppStoreVersion}} ניתנת להורדה-יש לך גרסה {{currentInstalledVersion}}.';
        break;
      case 'hi':
        message =
            '{{appName}} का एक नया संस्करण उपलब्ध है। आपके पास संस्करण {{currentInstalledVersion}} है, लेकिन अब {{currentAppStoreVersion}} उपलब्ध है।';
        break;
      case 'ht':
        message =
            'Yon nouvo vèsyon {{appName}} disponib! Vèsyon {{currentAppStoreVersion}} disponib, ou gen vèsyon {{currentInstalledVersion}}.';
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
            'Una nuova versione di {{appName}} è disponibile! La versione {{currentAppStoreVersion}} è ora disponibile, voi avete la {{currentInstalledVersion}}.';
        break;
      case 'ja':
        message =
            '現在のバージョンは、{{currentInstalledVersion}}です。{{appName}}の最新バージョン({{currentAppStoreVersion}})があります。';
        break;
      case 'kk':
        message =
            '{{appName}} қосымша жаңа нұсқасын жүктеп алыңыз! Жаңа нұсқасы: {{currentAppStoreVersion}}, қазіргі нұсқасы: {{currentInstalledVersion}}';
        break;
      case 'km':
        message =
            'មានការអាប់ដេតថ្មីកម្មវិធី {{appName}} ហើយ! កំណែអាប់ដែត {{currentAppStoreVersion}} គឺអាចប្រើប្រាប់បានជំនួស {{currentInstalledVersion}} បានហើយ។';
        break;
      case 'ko':
        message =
            '{{appName}}이 새 버전으로 업데이트되었습니다! 최신 버전 {{currentAppStoreVersion}}으로 업그레이드 가능합니다 - 현재 버전 {{currentInstalledVersion}}.';
        break;
      case 'ku':
        message =
            'وەشانی نوێی {{appName}} بەردەستە! وەشانی {{currentAppStoreVersion}} بەردەستە- تۆ وەشانی {{currentInstalledVersion}} دابەزاندوە.';
        break;
      case 'lt':
        message =
            'Išleista nauja programos {{appName}} versija! Versija {{currentAppStoreVersion}} yra prieinama, jūs turite {{currentInstalledVersion}}.';
        break;
      case 'mn':
        message =
            '{{appName}}-н шинэ хувилбар бэлэн боллоо! Таны одоогийн ашиглаж буй хувилбар {{currentInstalledVersion}} - Шинээр бэлэн болсон хувилбар нь {{currentAppStoreVersion}} юм .';
        break;
      case 'nb':
        message =
            'En ny versjon av {{appName}} er tilgjengelig! {{currentAppStoreVersion}} er nå tilgjengelig - du har {{currentInstalledVersion}}.';
        break;
      case 'nl':
        message =
            'Er is een nieuwe versie van {{appName}} beschikbaar! De nieuwe versie is {{currentAppStoreVersion}}, je gebruikt nu versie {{currentInstalledVersion}}.';
        break;
      case 'pt':
        message =
            'Há uma nova versão do {{appName}} disponível! A versão {{currentAppStoreVersion}} já está disponível, você tem a {{currentInstalledVersion}}.';
        break;
      case 'pl':
        message =
            'Nowa wersja {{appName}} jest dostępna! Wersja {{currentAppStoreVersion}} jest dostępna, Ty masz {{currentInstalledVersion}}.';
        break;
      case 'ps':
        message =
            'د {{appName}} آپلیکشن  نوې نسخه شتون لري! {{currentAppStoreVersion}} شتون لري، مګر تاسو اوس هم {{currentInstalledVersion}} کاروئ.';
        break;
      case 'ro':
        message =
            'O versiune nouă a aplicației {{appName}} este acum disponibilă! Actualizați la versiunea {{currentAppStoreVersion}} – aveți versiunea {{currentInstalledVersion}}.';
        break;
      case 'ru':
        message =
            'Доступна новая версия приложения {{appName}}! Новая версия: {{currentAppStoreVersion}}, текущая версия: {{currentInstalledVersion}}.';
        break;
      case 'sv':
        message =
            'En ny version av {{appName}} är tillgänglig! Version {{currentAppStoreVersion}} är tillgänglig - du har {{currentInstalledVersion}}.';
        break;
      case 'ta':
        message =
            '{{appName}}-ன் புதிய பதிப்பு {{currentAppStoreVersion}} இப்போது கிடைக்கிறது! உங்களிடம் {{currentInstalledVersion}} உள்ளது.';
        break;
      case 'te':
        message =
            '{{appName}} యాప్ యొక్క కొత్త వెర్షన్ అందుబాటులో ఉంది. వెర్షన్ {{currentAppStoreVersion}} అందుబాటులో ఉంది కానీ మీ దగ్గర {{currentInstalledVersion}} ఉంది.';
        break;
      case 'tr':
        message =
            '{{appName}} uygulamanızın yeni bir versiyonu mevcut! Versiyon {{currentAppStoreVersion}} şu anda erişilebilir, mevcut sürümünüz {{currentInstalledVersion}}.';
        break;
      case 'uk':
        message =
            'Доступна нова версія додатка {{appName}}! Нова версія: {{currentAppStoreVersion}}, поточна версія: {{currentInstalledVersion}}.';
        break;
      case 'uz':
        message =
            'Yangi {{appName}} talqin mavjud! {{currentAppStoreVersion}} talqin chiqdi — sizda hozirda {{currentInstalledVersion}} talqini mavjud.';
        break;
      case 'vi':
        message =
            'Đã có phiên bản mới của {{appName}}. Phiên bản {{currentAppStoreVersion}} đã sẵn sàng, bạn đang dùng {{currentInstalledVersion}}.';
        break;
      case 'zh':
        message =
            '{{appName}}有新的版本！您拥有{{currentInstalledVersion}}的版本可更新到{{currentAppStoreVersion}}的版本。';
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
      case 'bn':
        message = 'বাতিল';
        break;
      case 'da':
        message = 'IGNORER';
        break;
      case 'el':
        message = 'ΑΓΝΟΗΣTΕ';
        break;
      case 'es':
        message = 'IGNORAR';
        break;
      case 'fa':
        message = 'ردکردن';
        break;
      case 'fil':
        message = 'HUWAG PANSININ';
        break;
      case 'fr':
        message = 'IGNORER';
        break;
      case 'de':
        message = 'IGNORIEREN';
        break;
      case 'he':
        message = 'התעלם';
        break;
      case 'hi':
        message = 'नज़रअंदाज़ करें';
        break;
      case 'ht':
        message = 'INYORE';
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
      case 'ja':
        message = '今はしない';
        break;
      case 'kk':
        message = 'ЖОҚ';
        break;
      case 'km':
        message = 'មិនអើពើ';
        break;
      case 'ko':
        message = '무시';
        break;
      case 'ku':
        message = 'پشتگوێخستن';
        break;
      case 'lt':
        message = 'IGNORUOTI';
        break;
      case 'mn':
        message = 'Татгалзах';
        break;
      case 'nb':
        message = 'IGNORER';
        break;
      case 'nl':
        message = 'NEGEREN';
        break;
      case 'pt':
        message = 'IGNORAR';
        break;
      case 'pl':
        message = 'IGNORUJ';
        break;
      case 'ps':
        message = 'ردکول';
        break;
      case 'ro':
        message = 'Ignoră';
        break;
      case 'ru':
        message = 'НЕТ';
        break;
      case 'sv':
        message = 'AVBRYT';
        break;
      case 'ta':
        message = 'புறக்கணி';
        break;
      case 'te':
        message = 'తిరస్కరించండి';
        break;
      case 'tr':
        message = 'YOKSAY';
        break;
      case 'uk':
        message = 'НІ';
        break;
      case 'uz':
        message = "Yo'q";
        break;
      case 'vi':
        message = 'BỎ QUA';
        break;
      case 'zh':
        message = '不理';
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
        message = 'لاحقا';
        break;
      case 'bn':
        message = 'পরে';
        break;
      case 'da':
        message = 'SENERE';
        break;
      case 'el':
        message = 'ΑΡΓΟΤΕΡΑ';
        break;
      case 'es':
        message = 'MÁS TARDE';
        break;
      case 'fa':
        message = 'بعدا';
        break;
      case 'fil':
        message = 'MAMAYA';
        break;
      case 'fr':
        message = 'PLUS TARD';
        break;
      case 'de':
        message = 'SPÄTER';
        break;
      case 'he':
        message = 'אחר-כך';
        break;
      case 'hi':
        message = 'बाद में करें';
        break;
      case 'ht':
        message = 'PITA';
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
      case 'ja':
        message = '後で通知';
        break;
      case 'kk':
        message = 'КЕЙІН';
        break;
      case 'km':
        message = 'ពេលក្រោយ';
        break;
      case 'ko':
        message = '나중에';
        break;
      case 'ku':
        message = 'دواتر';
        break;
      case 'lt':
        message = 'ATNAUJINTI VĖLIAU';
        break;
      case 'mn':
        message = 'Дараа суулгах';
        break;
      case 'nb':
        message = 'SENERE';
        break;
      case 'nl':
        message = 'LATER';
        break;
      case 'pt':
        message = 'MAIS TARDE';
        break;
      case 'pl':
        message = 'PÓŹNIEJ';
        break;
      case 'ps':
        message = 'وروسته';
        break;
      case 'ro':
        message = 'Amână';
        break;
      case 'ru':
        message = 'ПОЗЖЕ';
        break;
      case 'sv':
        message = 'SENARE';
        break;
      case 'ta':
        message = 'பிறகு';
        break;
      case 'te':
        message = 'తరువాత';
        break;
      case 'tr':
        message = 'SONRA';
        break;
      case 'uk':
        message = 'ПІЗНІШЕ';
        break;
      case 'uz':
        message = "Keyinroq";
      case 'vi':
        message = 'ĐỂ SAU';
        break;
      case 'zh':
        message = '以后';
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
      case 'bn':
        message = 'এখন আপডেট করুন';
        break;
      case 'da':
        message = 'OPDATER NU';
        break;
      case 'el':
        message = 'ΕΝΗΜΕΡΩΣΗ';
        break;
      case 'es':
        message = 'ACTUALIZAR';
        break;
      case 'fa':
        message = 'بروزرسانی';
        break;
      case 'fil':
        message = 'I-UPDATE NA NGAYON';
        break;
      case 'fr':
        message = 'MAINTENANT';
        break;
      case 'de':
        message = 'AKTUALISIEREN';
        break;
      case 'he':
        message = 'עדכן';
        break;
      case 'hi':
        message = 'अभी नया संस्करण स्थापित करें';
        break;
      case 'ht':
        message = 'MIZAJOU KOUNYE A';
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
      case 'ja':
        message = 'アップデート';
        break;
      case 'kk':
        message = 'ЖАҢАРТУ';
        break;
      case 'km':
        message = 'អាប់ដេតឥឡូវនេះ';
        break;
      case 'ko':
        message = '지금 업데이트';
        break;
      case 'ku':
        message = 'نوێکردنەوە';
        break;
      case 'lt':
        message = 'ATNAUJINTI DABAR';
        break;
      case 'mn':
        message = 'Шинэчлэх';
        break;
      case 'nb':
        message = 'OPPDATER NÅ';
        break;
      case 'nl':
        message = 'NU UPDATEN';
        break;
      case 'pt':
        message = 'ATUALIZAR';
        break;
      case 'pl':
        message = 'AKTUALIZUJ';
        break;
      case 'ps':
        message = 'اوس تازه کړئ';
        break;
      case 'ro':
        message = 'ACTUALIZEAZĂ ACUM';
        break;
      case 'ru':
        message = 'ОБНОВИТЬ';
        break;
      case 'sv':
        message = 'UPPDATERA NU';
        break;
      case 'ta':
        message = 'இப்பொழுது புதுப்பிக்கவும்';
        break;
      case 'te':
        message = 'అప్‌డేట్‌ చేయండి';
        break;
      case 'tr':
        message = 'ŞİMDİ GÜNCELLE';
        break;
      case 'uk':
        message = 'ОНОВИТИ';
        break;
      case 'uz':
        message = "Yangilash";
        break;
      case 'vi':
        message = 'CẬP NHẬT';
        break;
      case 'zh':
        message = '更新';
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
      case 'bn':
        message = 'আপনি কি এখনই এটি আপডেট করতে চান?';
        break;
      case 'da':
        message = 'Vil du opdatere nu?';
        break;
      case 'el':
        message = 'Θέλετε να κάνετε την ενημέρωση τώρα;';
        break;
      case 'es':
        message = '¿Le gustaría actualizar ahora?';
        break;
      case 'fa':
        message = 'آیا بروزرسانی می‌کنید؟';
        break;
      case 'fil':
        message = 'Gusto mo bang i-update ito ngayon?';
        break;
      case 'fr':
        message = 'Voulez-vous mettre à jour maintenant ?';
        break;
      case 'de':
        message = 'Möchtest du jetzt aktualisieren?';
        break;
      case 'he':
        message = 'האם תרצה לעדכן עכשיו?';
        break;
      case 'hi':
        message = 'क्या आप इसे अभी नया संस्करण स्थापित करना चाहेंगे?';
        break;
      case 'ht':
        message = 'Èske ou vle mete aplikasyon an ajou kounye a?';
        break;
      case 'hu':
        message = 'Akarja most frissíteni?';
        break;
      case 'id':
        message = 'Apakah Anda ingin memperbaruinya sekarang?';
        break;
      case 'it':
        message = 'Vorresti aggiornare ora?';
        break;
      case 'ja':
        message = '今すぐアップデートしますか?';
        break;
      case 'kk':
        message = 'Қазір жаңартқыңыз келе ме?';
        break;
      case 'km':
        message = 'តើអ្នកចង់អាប់ដេតវាឥឡូវនេះទេ?';
        break;
      case 'ko':
        message = '지금 업데이트를 시작하시겠습니까?';
        break;
      case 'ku':
        message = 'دەتەوێت ئێستا نوێی بکەیەوە؟';
        break;
      case 'lt':
        message = 'Ar norite atnaujinti dabar?';
        break;
      case 'mn':
        message = 'Та одоо шинэчлэлтийг татаж авах уу?';
        break;
      case 'nb':
        message = 'Ønsker du å oppdatere nå?';
        break;
      case 'nl':
        message = 'Wil je de app nu updaten?';
        break;
      case 'pt':
        message = 'Você quer atualizar agora?';
        break;
      case 'pl':
        message = 'Czy chciałbyś zaktualizować teraz?';
        break;
      case 'ps':
        message = 'آی غواړئ دا اوس تازه کړئ؟';
        break;
      case 'ro':
        message = 'Vreți să actualizați acum?';
        break;
      case 'ru':
        message = 'Хотите обновить сейчас?';
        break;
      case 'sv':
        message = 'Vill du uppdatera nu?';
        break;
      case 'ta':
        message = 'இப்போது புதுப்பிக்க விரும்புகிறீர்களா?';
        break;
      case 'te':
        message = 'మీరు దీన్ని ఇప్పుడే అప్‌డేట్ చేయాలనుకుంటున్నారా?';
        break;
      case 'tr':
        message = 'Şimdi güncellemek ister misiniz?';
        break;
      case 'uk':
        message = 'Бажаєте оновити зараз?';
        break;
      case 'uz':
        message = "Hozir yangilashni xohlaysizmi?";
        break;
      case 'vi':
        message = 'Bạn có muốn cập nhật ứng dụng?';
        break;
      case 'zh':
        message = '您现在要更新应用程序吗？';
        break;
      case 'en':
      default:
        message = 'Would you like to update it now?';
        break;
    }
    return message;
  }

  /// The release notes message.
  /// Override this getter to provide a custom value. Values provided in the
  /// [message] function will be used over this value.
  String get releaseNotes {
    String message;
    switch (languageCode) {
      case 'ar':
        message = 'تفاصيل الاصدار';
        break;
      case 'da':
        message = 'Udgivelsesnoter';
        break;
      case 'de':
        message = 'Versionshinweise';
        break;
      case 'es':
        message = 'Notas De Lanzamiento';
        break;
      case 'fr':
        message = 'Notes de version';
        break;
      case 'he':
        message = 'חדש בגרסה';
        break;
      case 'hi':
        message = 'नए संस्करण का विवरण';
        break;
      case 'id':
        message = 'Catatan Rilis';
        break;
      case 'it':
        message = 'Note di rilascio';
        break;
      case 'ja':
        message = 'リリースノート';
        break;
      case 'ku':
        message = 'تیبینەکانی وەشان';
        break;
      case 'pt':
        message = 'Novidades';
        break;
      case 'ro':
        message = 'Detalii despre actualizare';
        break;
      case 'ru':
        message = 'Информация о выпуске';
        break;
      case 'te':
        message = 'విడుదల గమనికలు';
        break;
      case 'tr':
        message = 'Yayın Notları';
        break;

      case 'bn':
      case 'el':
      case 'fa':
      case 'fil':
      case 'ht':
      case 'hu':
      case 'kk':
      case 'km':
      case 'ko':
      case 'lt':
      case 'mn':
      case 'nb':
      case 'nl':
      case 'pl':
      case 'ps':
      case 'sv':
      case 'ta':
      case 'uk':
      case 'uz':
        message = "Yangi talqin ma'lumotlari";
        break;
      case 'vi':
      case 'zh':
      case 'en':
      default:
        message = 'Release Notes';
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
      case 'bn':
        message = 'আপডেট অ্যাপ্লিকেশন?';
        break;
      case 'da':
        message = 'Opdater App?';
        break;
      case 'el':
        message = 'Ενημέρωση εφαρμογής;';
        break;
      case 'es':
        message = '¿Actualizar la aplicación?';
        break;
      case 'fa':
        message = 'نسخه‌ی جدید';
        break;
      case 'fil':
        message = 'I-update ang app?';
        break;
      case 'fr':
        message = 'Mettre à jour l\'application ?';
        break;
      case 'de':
        message = 'App aktualisieren?';
        break;
      case 'he':
        message = 'לעדכן יישומון?';
        break;
      case 'hi':
        message = 'ऐप का नया संस्करण स्थापित करें?';
        break;
      case 'ht':
        message = 'Mete app la ajou?';
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
      case 'ja':
        message = 'アプリのアップデート';
        break;
      case 'kk':
        message = 'Жаңарту керек пе?';
        break;
      case 'km':
        message = 'អាប់ដេតកម្មវិធីទេ?';
        break;
      case 'ko':
        message = '앱을 업데이트하시겠습니까?';
        break;
      case 'ku':
        message = 'نوێکردنەوەی ئەپ؟';
        break;
      case 'lt':
        message = 'Atnaujinti programą?';
        break;
      case 'mn':
        message = 'Та шинэчлэлт хийх үү?';
        break;
      case 'nb':
        message = 'Oppdater app?';
        break;
      case 'nl':
        message = 'App updaten?';
        break;
      case 'pt':
        message = 'Atualizar aplicação?';
        break;
      case 'pl':
        message = 'Czy zaktualizować aplikację?';
        break;
      case 'ps':
        message = 'نوې نسخه';
        break;
      case 'ro':
        message = 'Actualizați aplicația?';
        break;
      case 'ru':
        message = 'Обновить?';
        break;
      case 'sv':
        message = 'Uppdatera App?';
        break;
      case 'ta':
        message = 'செயலியை புதுப்பிக்கவா?';
        break;
      case 'te':
        message = 'యాప్‌ని అప్‌డేట్‌ చేయాలా?';
        break;
      case 'tr':
        message = 'Uygulamayı Güncelle?';
        break;
      case 'uk':
        message = 'Оновити?';
        break;
      case 'uz':
        message = "Ilova yangilansinmi?";
        break;
      case 'vi':
        message = 'Cập nhật ứng dụng?';
        break;
      case 'zh':
        message = '更新应用程序？';
        break;
      case 'en':
      default:
        message = 'Update App?';
        break;
    }
    return message;
  }
}
