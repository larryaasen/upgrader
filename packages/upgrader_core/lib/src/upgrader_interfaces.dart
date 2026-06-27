import 'upgrader_package_info.dart';

abstract class UpgraderAppInfoProvider {
  Future<UpgraderPackageInfo?> getPackageInfo();
}

abstract class UpgraderPreferencesStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

abstract class UpgraderStoreLauncher {
  Future<bool> canLaunch(String url);
  Future<void> launch(String url, {required bool isAndroid});
}
