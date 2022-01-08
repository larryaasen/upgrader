/*
 * Copyright (c) 2021-2022 Larry Aasen. All rights reserved.
 */

import "package:os_detect/os_detect.dart" as platform;
import 'package:flutter/foundation.dart';

class UpgradeIO {
  /// The target operating system.
  static String get operatingSystem {
    try {
      return platform.operatingSystem;
    } catch (e) {
      return '';
    }
  }

  /// A string representing the version of the operating system or platform.
  static String get operatingSystemVersion {
    try {
      return platform.operatingSystemVersion;
    } catch (e) {
      return '';
    }
  }

  /// Whether the operating system is a version of Android.
  static bool get isAndroid {
    try {
      return platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Fuchsia.
  static bool get isFuchsia {
    try {
      return platform.isFuchsia;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of iOS.
  static bool get isIOS {
    try {
      return platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Linux.
  static bool get isLinux {
    try {
      return platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of macOS.
  static bool get isMacOS {
    try {
      return platform.isMacOS;
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
      return platform.isWindows;
    } catch (e) {
      return false;
    }
  }
}
