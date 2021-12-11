/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'dart:io';
import 'package:flutter/foundation.dart';

class UpgradeIO {
  /// The target operating system.
  static String get operatingSystem {
    try {
      return Platform.operatingSystem;
    } catch (e) {
      return '';
    }
  }

  /// A string representing the version of the operating system or platform.
  static String get operatingSystemVersion {
    try {
      return Platform.operatingSystemVersion;
    } catch (e) {
      return '';
    }
  }

  /// Whether the operating system is a version of Android.
  static bool get isAndroid {
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Fuchsia.
  static bool get isFuchsia {
    try {
      return Platform.isFuchsia;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of iOS.
  static bool get isIOS {
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Linux.
  static bool get isLinux {
    try {
      return Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of macOS.
  static bool get isMacOS {
    try {
      return Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  /// Whether the application was compiled to run on the web.
  static bool get isWeb {
    try {
      return kIsWeb;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Windows.
  static bool get isWindows {
    try {
      return Platform.isWindows;
    } catch (e) {
      return false;
    }
  }
}
