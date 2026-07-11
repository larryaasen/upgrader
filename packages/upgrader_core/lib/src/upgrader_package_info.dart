class UpgraderPackageInfo {
  const UpgraderPackageInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  UpgraderPackageInfo copyWith({
    String? appName,
    String? packageName,
    String? version,
    String? buildNumber,
  }) {
    return UpgraderPackageInfo(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
    );
  }
}
