# upgrader_core

The Dart-only core of the [upgrader](https://pub.dev/packages/upgrader) package: store lookup,
version evaluation, and the rules that decide whether an upgrade should be prompted.

This package has **no Flutter dependency**. It is intended for:

- Dart-only projects (CLI tools, servers, background isolates) that need to check whether a
  newer version of an app is available in a store.
- Advanced Flutter apps that want the decision logic without the bundled UI.

If you are building a Flutter app and want the ready-made upgrade prompt widgets
(`UpgradeAlert`, `UpgradeCard`), use the [upgrader](https://pub.dev/packages/upgrader) package
instead. It depends on this package and re-exports the core APIs, so you do not need to depend
on `upgrader_core` directly.

## Installation

```yaml
dependencies:
  upgrader_core: ^14.0.0
```

## Usage

Query a store directly:

```dart
import 'package:upgrader_core/upgrader_core.dart';

Future<void> main() async {
  final iTunes = ITunesSearchAPI();
  final response = await iTunes.lookupByBundleId('com.google.Maps');
  print('Latest App Store version: ${iTunes.version(response!)}');
}
```

Evaluate whether an upgrade should be prompted:

```dart
import 'package:http/http.dart' as http;
import 'package:upgrader_core/upgrader_core.dart';

Future<void> main() async {
  final engine = UpgraderEngine(
    state: UpgraderState(
      client: http.Client(),
      packageInfo: const UpgraderPackageInfo(
        appName: 'My App',
        packageName: 'com.example.myapp',
        version: '1.0.0',
        buildNumber: '1',
      ),
      upgraderPlatform: const UpgraderPlatform(
        currentOSType: UpgraderOSType.android,
      ),
    ),
  );

  await engine.updateVersionInfo();

  if (engine.isUpdateAvailable()) {
    print('Update available: ${engine.currentAppStoreVersion}');
    print('Store listing: ${engine.currentAppStoreListingURL}');
  }
}
```

## Key APIs

| API | Purpose |
| --- | --- |
| `UpgraderEngine` | Version evaluation and prompt decision rules. |
| `UpgraderState` | Immutable configuration and lookup results. |
| `UpgraderStoreController` | Selects the store to query for each platform. |
| `UpgraderAppStore` / `UpgraderPlayStore` / `UpgraderAppcastStore` | Store implementations. |
| `ITunesSearchAPI` / `PlayStoreSearchAPI` / `Appcast` | Low-level store lookup and parsing. |
| `UpgraderVersionInfo` | The version details retrieved from a store. |

### Host integration points

The engine does not perform platform I/O itself. Supply these when integrating:

| Interface | Responsibility |
| --- | --- |
| `UpgraderAppInfoProvider` | Supplies the installed app's package metadata. |
| `UpgraderPreferencesStore` | Persists the ignored version and last-alerted timestamps. |
| `UpgraderStoreLauncher` | Opens the store listing URL. |

## Versioning policy

`upgrader_core` and [`upgrader`](https://pub.dev/packages/upgrader) **share a major version, and
are allowed to drift on minor and patch.**

- The major version is always in lockstep: `upgrader_core 14.x` is always designed against
  `upgrader 14.x`.
- A breaking change in *either* package bumps the major version of *both*, and both are
  released together — even if one of them has no other changes.
- A change confined to one package bumps only that package's minor or patch version. A
  core-only fix does not force a no-op release of `upgrader`, and a Flutter-only fix does not
  force a no-op release of this package.
- `upgrader` depends on `upgrader_core: ^<lowest version it actually needs>`. When `upgrader`
  starts using a newly added core API, that lower bound is raised in the same release.

Rationale: the shared major version makes the compatible pairing obvious at a glance, with no
lookup table to maintain. Allowing minor and patch to drift avoids publishing meaningless
identical releases of one package every time the other gets a fix.

Because the version line is shared, this package's `CHANGELOG.md` retains the `upgrader`
history from before the 14.0.0 split.

## Publishing order

`upgrader` depends on this package by version rather than by path, so **`upgrader_core` must be
published first.** Publishing `upgrader` first would produce a release that no one can resolve.

1. `cd packages/upgrader_core && dart pub publish`
2. Wait for the new version to be live on pub.dev.
3. `cd packages/upgrader && flutter pub publish`

Inside the [upgrader repository](https://github.com/larryaasen/upgrader) the Dart workspace
resolves this package from `packages/upgrader_core`, so local development, tests, and CI never
depend on the published version.

## Command-line tools

```bash
dart run upgrader_core:itunes_lookup bundleid=com.google.Maps
dart run upgrader_core:playstore_lookup id=com.google.android.apps.maps
```

## License

BSD 3-Clause. See [LICENSE](LICENSE).
