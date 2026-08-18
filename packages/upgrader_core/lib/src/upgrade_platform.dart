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
  }) : _current = current;

  final String? _current;
  final UpgraderOSType currentOSType;

  /// The current platform name, such as `'android'` or `'ios'`.
  ///
  /// Defaults to the lowercase name of [currentOSType] when not provided.
  String get current => _current ?? _defaultCurrent(currentOSType);

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
