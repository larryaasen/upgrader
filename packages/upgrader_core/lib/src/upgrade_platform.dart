enum UpgraderOSType {
  android,
  fuchsia,
  ios,
  linux,
  macos,
  web,
  windows,
}

class UpgraderPlatform {
  const UpgraderPlatform({
    required this.currentOSType,
    String? current,
  }) : current = current ?? _defaultCurrent(currentOSType);

  final String current;
  final UpgraderOSType currentOSType;

  String get currentPlatform => current;

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

  static String _defaultCurrent(UpgraderOSType type) {
    return switch (type) {
      UpgraderOSType.android => 'android',
      UpgraderOSType.fuchsia => 'fuchsia',
      UpgraderOSType.ios => 'ios',
      UpgraderOSType.linux => 'linux',
      UpgraderOSType.macos => 'macos',
      UpgraderOSType.web => 'web',
      UpgraderOSType.windows => 'windows',
    };
  }
}
