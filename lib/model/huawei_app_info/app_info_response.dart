import 'package:json_annotation/json_annotation.dart';

part 'app_info_response.g.dart';

@JsonSerializable()
class AppInfoResponse {
  @JsonKey(name: "ret")
  Ret? ret;
  @JsonKey(name: "appInfo")
  AppInfo? appInfo;
  @JsonKey(name: "auditInfo")
  AuditInfo? auditInfo;
  @JsonKey(name: "languages")
  List<Language>? languages;

  AppInfoResponse({
    this.ret,
    this.appInfo,
    this.auditInfo,
    this.languages,
  });

  factory AppInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$AppInfoResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AppInfoResponseToJson(this);
}

@JsonSerializable()
class AppInfo {
  @JsonKey(name: "releaseState")
  int? releaseState;
  @JsonKey(name: "defaultLang")
  String? defaultLang;
  @JsonKey(name: "parentType")
  int? parentType;
  @JsonKey(name: "childType")
  int? childType;
  @JsonKey(name: "grandChildType")
  int? grandChildType;
  @JsonKey(name: "privacyPolicy")
  String? privacyPolicy;
  @JsonKey(name: "appAdapters")
  String? appAdapters;
  @JsonKey(name: "isFree")
  int? isFree;
  @JsonKey(name: "price")
  String? price;
  @JsonKey(name: "priceDetail")
  String? priceDetail;
  @JsonKey(name: "publishCountry")
  String? publishCountry;
  @JsonKey(name: "contentRate")
  String? contentRate;
  @JsonKey(name: "hispaceAutoDown")
  int? hispaceAutoDown;
  @JsonKey(name: "appTariffType")
  String? appTariffType;
  @JsonKey(name: "developerNameCn")
  String? developerNameCn;
  @JsonKey(name: "developerNameEn")
  String? developerNameEn;
  @JsonKey(name: "developerAddr")
  String? developerAddr;
  @JsonKey(name: "developerEmail")
  String? developerEmail;
  @JsonKey(name: "developerPhone")
  String? developerPhone;
  @JsonKey(name: "developerWebsite")
  String? developerWebsite;
  @JsonKey(name: "certificateURLs")
  String? certificateUrLs;
  @JsonKey(name: "publicationURLs")
  String? publicationUrLs;
  @JsonKey(name: "cultureRecordURLs")
  String? cultureRecordUrLs;
  @JsonKey(name: "updateTime")
  DateTime? updateTime;
  @JsonKey(name: "versionNumber")
  String? versionNumber;
  @JsonKey(name: "familyShareTag")
  int? familyShareTag;
  @JsonKey(name: "deviceTypes")
  List<DeviceType>? deviceTypes;

  AppInfo({
    this.releaseState,
    this.defaultLang,
    this.parentType,
    this.childType,
    this.grandChildType,
    this.privacyPolicy,
    this.appAdapters,
    this.isFree,
    this.price,
    this.priceDetail,
    this.publishCountry,
    this.contentRate,
    this.hispaceAutoDown,
    this.appTariffType,
    this.developerNameCn,
    this.developerNameEn,
    this.developerAddr,
    this.developerEmail,
    this.developerPhone,
    this.developerWebsite,
    this.certificateUrLs,
    this.publicationUrLs,
    this.cultureRecordUrLs,
    this.updateTime,
    this.versionNumber,
    this.familyShareTag,
    this.deviceTypes,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      _$AppInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AppInfoToJson(this);
}

@JsonSerializable()
class DeviceType {
  @JsonKey(name: "deviceType")
  int? deviceType;
  @JsonKey(name: "appAdapters")
  String? appAdapters;

  DeviceType({
    this.deviceType,
    this.appAdapters,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) =>
      _$DeviceTypeFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTypeToJson(this);
}

@JsonSerializable()
class AuditInfo {
  @JsonKey(name: "auditOpinion")
  String? auditOpinion;

  AuditInfo({
    this.auditOpinion,
  });

  factory AuditInfo.fromJson(Map<String, dynamic> json) =>
      _$AuditInfoFromJson(json);

  Map<String, dynamic> toJson() => _$AuditInfoToJson(this);
}

@JsonSerializable()
class Language {
  @JsonKey(name: "lang")
  String? lang;
  @JsonKey(name: "appName")
  String? appName;
  @JsonKey(name: "appDesc")
  String? appDesc;
  @JsonKey(name: "briefInfo")
  String? briefInfo;
  @JsonKey(name: "newFeatures")
  String? newFeatures;
  @JsonKey(name: "icon")
  String? icon;
  @JsonKey(name: "showType")
  int? showType;
  @JsonKey(name: "videoShowType")
  int? videoShowType;
  @JsonKey(name: "introPic")
  String? introPic;
  @JsonKey(name: "deviceMaterials")
  List<DeviceMaterial>? deviceMaterials;
  @JsonKey(name: "rcmdPic")
  String? rcmdPic;

  Language({
    this.lang,
    this.appName,
    this.appDesc,
    this.briefInfo,
    this.newFeatures,
    this.icon,
    this.showType,
    this.videoShowType,
    this.introPic,
    this.deviceMaterials,
    this.rcmdPic,
  });

  factory Language.fromJson(Map<String, dynamic> json) =>
      _$LanguageFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageToJson(this);
}

@JsonSerializable()
class DeviceMaterial {
  @JsonKey(name: "deviceType")
  int? deviceType;
  @JsonKey(name: "appIcon")
  String? appIcon;
  @JsonKey(name: "screenShots")
  List<String?>? screenShots;
  @JsonKey(name: "showType")
  int? showType;
  @JsonKey(name: "vrCoverLayeredImage")
  List<dynamic>? vrCoverLayeredImage;
  @JsonKey(name: "vrRecomGraphic4to3")
  List<dynamic>? vrRecomGraphic4To3;
  @JsonKey(name: "vrRecomGraphic1to1")
  List<dynamic>? vrRecomGraphic1To1;
  @JsonKey(name: "promoGraphics")
  List<dynamic>? promoGraphics;
  @JsonKey(name: "videoShowType")
  int? videoShowType;
  @JsonKey(name: "rcmdPics")
  String? rcmdPics;

  DeviceMaterial({
    this.deviceType,
    this.appIcon,
    this.screenShots,
    this.showType,
    this.vrCoverLayeredImage,
    this.vrRecomGraphic4To3,
    this.vrRecomGraphic1To1,
    this.promoGraphics,
    this.videoShowType,
    this.rcmdPics,
  });

  factory DeviceMaterial.fromJson(Map<String, dynamic> json) =>
      _$DeviceMaterialFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceMaterialToJson(this);
}

@JsonSerializable()
class Ret {
  @JsonKey(name: "code")
  int? code;
  @JsonKey(name: "msg")
  String? msg;

  Ret({
    this.code,
    this.msg,
  });

  factory Ret.fromJson(Map<String, dynamic> json) => _$RetFromJson(json);

  Map<String, dynamic> toJson() => _$RetToJson(this);
}
