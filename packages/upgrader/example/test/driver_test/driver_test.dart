// Copyright 2022 Larry Aasen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path_d;

void main() {
  late FlutterDriver driver;

  Future<void> verifyText(String text) async {
    print('verify start: $text');
    await driver.waitFor(find.text(text));
    print('verify end');
  }

  group('Driver Test:', () {
    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
      print('pwd: ${Directory.current.path}');
      final currentPath = path_d.dirname(Platform.script.path);
      print('currentPath: $currentPath');
      final screenshotsPath = path_d.join(currentPath, 'screenshots');
      print('screenshots path: $screenshotsPath');
      driver = await FlutterDriver.connect();
      final health = await driver.checkHealth();
      print(health.status);

      // Wait for the first frame to be rasterized during the app launch.
      await driver.waitUntilFirstFrameRasterized();
    });

    // Close the connection to the driver after the tests have completed
    tearDownAll(() async {
      await driver.close();
    });

    test('verify app started', () async {
      print('test started');
      await driver.waitFor(find.text('Upgrader Driver App'));
      await driver.waitFor(find.text('Dialog Alert'));
      await driver.waitFor(find.text('Dialog Alert - Cupertino'));
      print('test ended');
    });

    test('verify alert', () async {
      print('test started');
      await driver.tap(find.text('Dialog Alert'));
      await driver.waitFor(find.text('Update App?'));
      await driver.waitFor(find.text('Would you like to update it now?'));
      await driver.waitFor(find.text('Release Notes'));
      await driver.waitFor(find.text('IGNORE'));
      await driver.waitFor(find.text('LATER'));
      await driver.waitFor(find.text('UPDATE NOW'));
      await driver.tap(find.text('IGNORE'));
      print('test ended');
    });

    test('verify alert - cupertino', () async {
      print('test started');
      await driver.tap(find.text('Dialog Alert - Cupertino'));

      await verifyText('Update App?');
      await verifyText('Would you like to update it now?');
      await verifyText('Release Notes');
      await verifyText('IGNORE');
      await verifyText('LATER');
      await verifyText('UPDATE NOW');

      await driver.tap(find.text('IGNORE'));
      print('test ended');
    });
  });
}

Future<void> takeScreenshot(FlutterDriver driver, String path) async {
  final currentPath = path_d.dirname(Platform.script.path);
  final uri = path_d.join(currentPath, 'screenshots', path);

  await driver.waitUntilNoTransientCallbacks();
  sleep(const Duration(seconds: 1));
  final pixels = await driver.screenshot();
  final file = File(uri);
  await file.writeAsBytes(pixels);
  print('saved screenshot: $uri');
}
