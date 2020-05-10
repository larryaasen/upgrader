class AppUpdateInfo {
  final bool updateAvailable;
  final int availableVersionCode;

  AppUpdateInfo(this.updateAvailable, this.availableVersionCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppUpdateInfo &&
              runtimeType == other.runtimeType &&
              updateAvailable == other.updateAvailable &&
              availableVersionCode == other.availableVersionCode;

  @override
  int get hashCode =>
      updateAvailable.hashCode ^
      availableVersionCode.hashCode;

  @override
  String toString() => 'InAppUpdateState{updateAvailable: $updateAvailable, '
      'availableVersionCode: $availableVersionCode}';
}
