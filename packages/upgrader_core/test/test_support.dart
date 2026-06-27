import 'package:upgrader_core/upgrader_core.dart';

class MockUpgraderPlatform extends UpgraderPlatform {
  MockUpgraderPlatform({
    bool android = false,
    bool fuchsia = false,
    bool ios = false,
    bool linux = false,
    bool macos = false,
    bool web = false,
    bool windows = false,
  }) : super(
          currentOSType: android
              ? UpgraderOSType.android
              : fuchsia
                  ? UpgraderOSType.fuchsia
                  : ios
                      ? UpgraderOSType.ios
                      : linux
                          ? UpgraderOSType.linux
                          : macos
                              ? UpgraderOSType.macos
                              : web
                                  ? UpgraderOSType.web
                                  : windows
                                      ? UpgraderOSType.windows
                                      : UpgraderOSType.android,
          current: android
              ? 'android'
              : fuchsia
                  ? 'fuchsia'
                  : ios
                      ? 'ios'
                      : linux
                          ? 'linux'
                          : macos
                              ? 'macos'
                              : web
                                  ? 'web'
                                  : windows
                                      ? 'windows'
                                      : 'android',
        );
}

bool mapsEqual(Map<String, String>? a, Map<String, String>? b) {
  if (a == null || b == null) {
    return a == b;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
