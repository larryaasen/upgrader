/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:version/version.dart';
import 'package:xml/xml.dart' as xml;

/// The [Appcast] class is used to download an Appcast, based on the Sparkle
/// framework by Andy Matuschak.
/// Documentation: https://sparkle-project.org/documentation/publishing/
/// An Appcast is an RSS feed with one channel that has a collection of items
/// that each describe one app version.
class Appcast {
  /// Provide an HTTP Client that can be replaced for mock testing.
  http.Client client;

  Appcast({
    this.client,
  }) {
    if (this.client == null) {
      this.client = http.Client();
    }
  }

  /// The items in the Appcast.
  List<AppcastItem> items;

  AndroidDeviceInfo _androidInfo;
  IosDeviceInfo _iosInfo;
  String osVersionString;

  /// Returns the latest item in the Appcast based on OS, OS version, and app
  /// version.
  AppcastItem bestItem() {
    if (items == null) {
      return null;
    }

    AppcastItem bestItem;
    items.forEach((AppcastItem item) {
      if (item.hostSupportsItem(osVersion: osVersionString)) {
        if (bestItem == null ||
            Version.parse(item.versionString) >
                Version.parse(bestItem.versionString)) {
          bestItem = item;
        }
      }
    });
    return bestItem;
  }

  /// Download the Appcast from [appCastURL].
  Future<List<AppcastItem>> parseAppcastItemsFromUri(String appCastURL) async {
    await _getDeviceInfo();

    http.Response response;
    try {
      response = await client.get(appCastURL);
    } catch (e) {
      print(e);
      return null;
    }
    final contents = response.body;
    return parseItemsFromXMLString(contents);
  }

  /// Load the Appcast from [file].
  Future<List<AppcastItem>> parseAppcastItemsFromFile(File file) async {
    await _getDeviceInfo();
    final contents = await file.readAsString();
    return parseItemsFromXMLString(contents);
  }

  List<AppcastItem> parseItemsFromXMLString(String xmlString) {
    this.items = null;

    if (xmlString == null || xmlString.isEmpty) {
      return null;
    }

    try {
      // Parse the XML
      final document = xml.parse(xmlString);

      List<AppcastItem> items = List<AppcastItem>();

      // look for all item elements in the rss/channel
      document.findAllElements('item').forEach((xml.XmlElement itemElement) {
        String title;
        String itemDescription;
        String dateString;
        String fileURL;
        String maximumSystemVersion;
        String minimumSystemVersion;
        String osString;
        final tags = List<String>();
        String newVersion;
        String itemVersion;
        String enclosureVersion;

        itemElement.children.forEach((xml.XmlNode childNode) {
          if (childNode is xml.XmlElement) {
            final String name = childNode.name.toString();
            if (name == AppcastConstants.ElementTitle) {
              title = childNode.text;
            } else if (name == AppcastConstants.ElementDescription) {
              itemDescription = childNode.text;
            } else if (name == AppcastConstants.ElementEnclosure) {
              childNode.attributes.forEach((xml.XmlAttribute attribute) {
                if (attribute.name.toString() ==
                    AppcastConstants.AttributeVersion) {
                  enclosureVersion = attribute.value;
                } else if (attribute.name.toString() ==
                    AppcastConstants.AttributeOsType) {
                  osString = attribute.value;
                } else if (attribute.name.toString() ==
                    AppcastConstants.AttributeURL) {
                  fileURL = attribute.value;
                }
              });
            } else if (name == AppcastConstants.ElementMaximumSystemVersion) {
              maximumSystemVersion = childNode.text;
            } else if (name == AppcastConstants.ElementMinimumSystemVersion) {
              minimumSystemVersion = childNode.text;
            } else if (name == AppcastConstants.ElementPubDate) {
              dateString = childNode.text;
            } else if (name == AppcastConstants.ElementTags) {
              childNode.children.forEach((xml.XmlNode tagChildNode) {
                if (tagChildNode is xml.XmlElement) {
                  final String tagName = tagChildNode.name.toString();
                  tags.add(tagName);
                }
              });
            } else if (name == AppcastConstants.AttributeVersion) {
              itemVersion = childNode.text;
            }
          }
        });

        newVersion = itemVersion == null ? enclosureVersion : itemVersion;

        // There must be a version
        if (newVersion == null || newVersion.isEmpty) {
          return null;
        }

        final item = AppcastItem(
          title: title,
          itemDescription: itemDescription,
          dateString: dateString,
          maximumSystemVersion: maximumSystemVersion,
          minimumSystemVersion: minimumSystemVersion,
          osString: osString,
          tags: tags,
          fileURL: fileURL,
          versionString: newVersion,
        );
        items.add(item);
      });

      this.items = items;
    } catch (e) {
      print(e);
    }

    return this.items;
  }

  Future<bool> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      _androidInfo = await deviceInfo.androidInfo;
      osVersionString = _androidInfo.version.baseOS;
    } else if (Platform.isIOS) {
      _iosInfo = await deviceInfo.iosInfo;
      osVersionString = _iosInfo.systemVersion;
    }
    return true;
  }
}

class AppcastItem {
  final String title;
  final String dateString;
  final String itemDescription;
  final String releaseNotesURL;
  final String minimumSystemVersion;
  final String maximumSystemVersion;
  final String fileURL;
  final int contentLength;
  final String versionString;
  final String osString;
  final String displayVersionString;
  final String infoURL;
  final List<String> tags;

  AppcastItem({
    this.title,
    this.dateString,
    this.itemDescription,
    this.releaseNotesURL,
    this.minimumSystemVersion,
    this.maximumSystemVersion,
    this.fileURL,
    this.contentLength,
    this.versionString,
    this.osString,
    this.displayVersionString,
    this.infoURL,
    this.tags,
  });

  /// Returns true if the tags ([AppcastConstants.ElementTags]) contains
  /// critical update ([AppcastConstants.ElementCriticalUpdate]).
  bool get isCriticalUpdate => this.tags == null
      ? false
      : this.tags.contains(AppcastConstants.ElementCriticalUpdate);

  bool hostSupportsItem({@required String osVersion, String currentPlatform}) {
    bool supported = true;
    if (osString != null && osString.isNotEmpty) {
      final platformEnum = 'TargetPlatform.' + osString;
      currentPlatform = currentPlatform == null
          ? defaultTargetPlatform.toString()
          : 'TargetPlatform.' + currentPlatform;
      supported = platformEnum == currentPlatform;
    }

    if (supported && osVersion != null && osVersion.isNotEmpty) {
      final osVersionValue = Version.parse(osVersion);
      if (maximumSystemVersion != null) {
        final maxVersion = Version.parse(maximumSystemVersion);
        if (osVersionValue > maxVersion) {
          supported = false;
        }
      }
      if (supported && minimumSystemVersion != null) {
        final minVersion = Version.parse(minimumSystemVersion);
        if (osVersionValue < minVersion) {
          supported = false;
        }
      }
    }
    return supported;
  }
}

/// These constants taken from:
/// https://github.com/sparkle-project/Sparkle/blob/master/Sparkle/SUConstants.m
class AppcastConstants {
  static const String AttributeDeltaFrom = "sparkle:deltaFrom";
  static const String AttributeDSASignature = "sparkle:dsaSignature";
  static const String AttributeEDSignature = "sparkle:edSignature";
  static const String AttributeShortVersionString =
      "sparkle:shortVersionString";
  static const String AttributeVersion = "sparkle:version";
  static const String AttributeOsType = "sparkle:os";

  static const String ElementCriticalUpdate = "sparkle:criticalUpdate";
  static const String ElementDeltas = "sparkle:deltas";
  static const String ElementMinimumSystemVersion =
      "sparkle:minimumSystemVersion";
  static const String ElementMaximumSystemVersion =
      "sparkle:maximumSystemVersion";
  static const String ElementReleaseNotesLink = "sparkle:releaseNotesLink";
  static const String ElementTags = "sparkle:tags";

  static const String AttributeURL = "url";
  static const String AttributeLength = "length";

  static const String ElementDescription = "description";
  static const String ElementEnclosure = "enclosure";
  static const String ElementLink = "link";
  static const String ElementPubDate = "pubDate";
  static const String ElementTitle = "title";
}
