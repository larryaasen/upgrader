// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_info_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppInfoResponse _$AppInfoResponseFromJson(Map<String, dynamic> json) =>
    AppInfoResponse(
      ret: json['ret'] == null
          ? null
          : Ret.fromJson(json['ret'] as Map<String, dynamic>),
      appInfo: json['appInfo'] == null
          ? null
          : AppInfo.fromJson(json['appInfo'] as Map<String, dynamic>),
      auditInfo: json['auditInfo'] == null
          ? null
          : AuditInfo.fromJson(json['auditInfo'] as Map<String, dynamic>),
      languages: (json['languages'] as List<dynamic>?)
          ?.map((e) => Language.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppInfoResponseToJson(AppInfoResponse instance) =>
    <String, dynamic>{
      'ret': instance.ret,
      'appInfo': instance.appInfo,
      'auditInfo': instance.auditInfo,
      'languages': instance.languages,
    };

AppInfo _$AppInfoFromJson(Map<String, dynamic> json) => AppInfo(
      releaseState: (json['releaseState'] as num?)?.toInt(),
      defaultLang: json['defaultLang'] as String?,
      parentType: (json['parentType'] as num?)?.toInt(),
      childType: (json['childType'] as num?)?.toInt(),
      grandChildType: (json['grandChildType'] as num?)?.toInt(),
      privacyPolicy: json['privacyPolicy'] as String?,
      appAdapters: json['appAdapters'] as String?,
      isFree: (json['isFree'] as num?)?.toInt(),
      price: json['price'] as String?,
      priceDetail: json['priceDetail'] as String?,
      publishCountry: json['publishCountry'] as String?,
      contentRate: json['contentRate'] as String?,
      hispaceAutoDown: (json['hispaceAutoDown'] as num?)?.toInt(),
      appTariffType: json['appTariffType'] as String?,
      developerNameCn: json['developerNameCn'] as String?,
      developerNameEn: json['developerNameEn'] as String?,
      developerAddr: json['developerAddr'] as String?,
      developerEmail: json['developerEmail'] as String?,
      developerPhone: json['developerPhone'] as String?,
      developerWebsite: json['developerWebsite'] as String?,
      certificateUrLs: json['certificateURLs'] as String?,
      publicationUrLs: json['publicationURLs'] as String?,
      cultureRecordUrLs: json['cultureRecordURLs'] as String?,
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      versionNumber: json['versionNumber'] as String?,
      familyShareTag: (json['familyShareTag'] as num?)?.toInt(),
      deviceTypes: (json['deviceTypes'] as List<dynamic>?)
          ?.map((e) => DeviceType.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AppInfoToJson(AppInfo instance) => <String, dynamic>{
      'releaseState': instance.releaseState,
      'defaultLang': instance.defaultLang,
      'parentType': instance.parentType,
      'childType': instance.childType,
      'grandChildType': instance.grandChildType,
      'privacyPolicy': instance.privacyPolicy,
      'appAdapters': instance.appAdapters,
      'isFree': instance.isFree,
      'price': instance.price,
      'priceDetail': instance.priceDetail,
      'publishCountry': instance.publishCountry,
      'contentRate': instance.contentRate,
      'hispaceAutoDown': instance.hispaceAutoDown,
      'appTariffType': instance.appTariffType,
      'developerNameCn': instance.developerNameCn,
      'developerNameEn': instance.developerNameEn,
      'developerAddr': instance.developerAddr,
      'developerEmail': instance.developerEmail,
      'developerPhone': instance.developerPhone,
      'developerWebsite': instance.developerWebsite,
      'certificateURLs': instance.certificateUrLs,
      'publicationURLs': instance.publicationUrLs,
      'cultureRecordURLs': instance.cultureRecordUrLs,
      'updateTime': instance.updateTime?.toIso8601String(),
      'versionNumber': instance.versionNumber,
      'familyShareTag': instance.familyShareTag,
      'deviceTypes': instance.deviceTypes,
    };

DeviceType _$DeviceTypeFromJson(Map<String, dynamic> json) => DeviceType(
      deviceType: (json['deviceType'] as num?)?.toInt(),
      appAdapters: json['appAdapters'] as String?,
    );

Map<String, dynamic> _$DeviceTypeToJson(DeviceType instance) =>
    <String, dynamic>{
      'deviceType': instance.deviceType,
      'appAdapters': instance.appAdapters,
    };

AuditInfo _$AuditInfoFromJson(Map<String, dynamic> json) => AuditInfo(
      auditOpinion: json['auditOpinion'] as String?,
    );

Map<String, dynamic> _$AuditInfoToJson(AuditInfo instance) => <String, dynamic>{
      'auditOpinion': instance.auditOpinion,
    };

Language _$LanguageFromJson(Map<String, dynamic> json) => Language(
      lang: json['lang'] as String?,
      appName: json['appName'] as String?,
      appDesc: json['appDesc'] as String?,
      briefInfo: json['briefInfo'] as String?,
      newFeatures: json['newFeatures'] as String?,
      icon: json['icon'] as String?,
      showType: (json['showType'] as num?)?.toInt(),
      videoShowType: (json['videoShowType'] as num?)?.toInt(),
      introPic: json['introPic'] as String?,
      deviceMaterials: (json['deviceMaterials'] as List<dynamic>?)
          ?.map((e) => DeviceMaterial.fromJson(e as Map<String, dynamic>))
          .toList(),
      rcmdPic: json['rcmdPic'] as String?,
    );

Map<String, dynamic> _$LanguageToJson(Language instance) => <String, dynamic>{
      'lang': instance.lang,
      'appName': instance.appName,
      'appDesc': instance.appDesc,
      'briefInfo': instance.briefInfo,
      'newFeatures': instance.newFeatures,
      'icon': instance.icon,
      'showType': instance.showType,
      'videoShowType': instance.videoShowType,
      'introPic': instance.introPic,
      'deviceMaterials': instance.deviceMaterials,
      'rcmdPic': instance.rcmdPic,
    };

DeviceMaterial _$DeviceMaterialFromJson(Map<String, dynamic> json) =>
    DeviceMaterial(
      deviceType: (json['deviceType'] as num?)?.toInt(),
      appIcon: json['appIcon'] as String?,
      screenShots: (json['screenShots'] as List<dynamic>?)
          ?.map((e) => e as String?)
          .toList(),
      showType: (json['showType'] as num?)?.toInt(),
      vrCoverLayeredImage: json['vrCoverLayeredImage'] as List<dynamic>?,
      vrRecomGraphic4To3: json['vrRecomGraphic4to3'] as List<dynamic>?,
      vrRecomGraphic1To1: json['vrRecomGraphic1to1'] as List<dynamic>?,
      promoGraphics: json['promoGraphics'] as List<dynamic>?,
      videoShowType: (json['videoShowType'] as num?)?.toInt(),
      rcmdPics: json['rcmdPics'] as String?,
    );

Map<String, dynamic> _$DeviceMaterialToJson(DeviceMaterial instance) =>
    <String, dynamic>{
      'deviceType': instance.deviceType,
      'appIcon': instance.appIcon,
      'screenShots': instance.screenShots,
      'showType': instance.showType,
      'vrCoverLayeredImage': instance.vrCoverLayeredImage,
      'vrRecomGraphic4to3': instance.vrRecomGraphic4To3,
      'vrRecomGraphic1to1': instance.vrRecomGraphic1To1,
      'promoGraphics': instance.promoGraphics,
      'videoShowType': instance.videoShowType,
      'rcmdPics': instance.rcmdPics,
    };

Ret _$RetFromJson(Map<String, dynamic> json) => Ret(
      code: (json['code'] as num?)?.toInt(),
      msg: json['msg'] as String?,
    );

Map<String, dynamic> _$RetToJson(Ret instance) => <String, dynamic>{
      'code': instance.code,
      'msg': instance.msg,
    };
