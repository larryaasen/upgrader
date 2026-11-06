/*
 * Copyright (c) 2021-2024 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:platform/platform.dart';

enum UpgraderOSType {
  android,
  fuchsia,
  ios,
  linux,
  macos,
  web,
  windows,
}

/// A class that indicates which OS this code is running on.
class UpgraderOS {
  String? _current;
  UpgraderOSType? _currentOSType;

  String get current {
    if (_current != null) return _current!;
    _current = isAndroid
        ? 'android'
        : isFuchsia
            ? 'fuchsia'
            : isIOS
                ? 'ios'
                : isLinux
                    ? 'linux'
                    : isMacOS
                        ? 'macos'
                        : isWeb
                            ? 'web'
                            : isWindows
                                ? 'windows'
                                : '';
    return _current ?? '';
  }

  UpgraderOSType get currentOSType {
    if (_currentOSType != null) return _currentOSType!;
    _currentOSType = isAndroid
        ? UpgraderOSType.android
        : isFuchsia
            ? UpgraderOSType.fuchsia
            : isIOS
                ? UpgraderOSType.ios
                : isLinux
                    ? UpgraderOSType.linux
                    : isMacOS
                        ? UpgraderOSType.macos
                        : isWeb
                            ? UpgraderOSType.web
                            : isWindows
                                ? UpgraderOSType.windows
                                : UpgraderOSType.android;
    return _currentOSType ?? UpgraderOSType.android;
  }

  /// The target operating system.
  String get operatingSystem {
    try {
      return NativePlatform.current!.operatingSystem;
    } catch (e) {
      return '';
    }
  }

  /// A string representing the version of the operating system or platform.
  String get operatingSystemVersion {
    try {
      return NativePlatform.current!.operatingSystemVersion;
    } catch (e) {
      return '';
    }
  }

  /// Whether the operating system is a version of Android.
  bool get isAndroid {
    try {
      return Platform.current.isAndroid;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Fuchsia.
  bool get isFuchsia {
    try {
      return Platform.current.isFuchsia;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of iOS.
  bool get isIOS {
    try {
      return Platform.current.isIOS;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Linux.
  bool get isLinux {
    try {
      return Platform.current.isLinux;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of macOS.
  bool get isMacOS {
    try {
      return Platform.current.isMacOS;
    } catch (e) {
      return false;
    }
  }

  /// Whether the application was compiled to run on the web.
  bool get isWeb {
    try {
      return kIsWeb;
    } catch (e) {
      return false;
    }
  }

  /// Whether the operating system is a version of Windows.
  bool get isWindows {
    try {
      return Platform.current.isWindows;
    } catch (e) {
      return false;
    }
  }

  /// Get the current OS type formatted, such as 'Android', 'iOS', etc.
  String get currentTypeFormatted {
    return switch (currentOSType) {
      UpgraderOSType.android => 'Android',
      UpgraderOSType.fuchsia => 'Fuchsia',
      UpgraderOSType.ios => 'iOS',
      UpgraderOSType.linux => 'Linux',
      UpgraderOSType.macos => 'macOS',
      UpgraderOSType.web => 'Web',
      UpgraderOSType.windows => 'Windows',
    };
  }

  @override
  String toString() {
    return 'operatingSystem: $operatingSystem, version: $operatingSystemVersion';
  }
}

/// A class to mock [UpgraderOS] for testing.
class MockUpgraderOS extends UpgraderOS {
  MockUpgraderOS({
    this.os = '',
    this.osv = '',
    this.android = false,
    this.fuchsia = false,
    this.ios = false,
    this.linux = false,
    this.macos = false,
    this.web = false,
    this.windows = false,
  });

  final String os;
  final String osv;
  final bool android;
  final bool fuchsia;
  final bool ios;
  final bool linux;
  final bool macos;
  final bool web;
  final bool windows;

  @override
  String get operatingSystem => os;

  @override
  String get operatingSystemVersion => osv;

  @override
  bool get isAndroid => android;

  @override
  bool get isFuchsia => fuchsia;

  @override
  bool get isIOS => ios;

  @override
  bool get isLinux => linux;

  @override
  bool get isMacOS => macos;

  @override
  bool get isWeb => web;

  @override
  bool get isWindows => windows;
}
