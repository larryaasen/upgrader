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

import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Driver Test:', () {
    late FlutterDriver driver;

    // Connect to the Flutter driver before running any tests
    setUpAll(() async {
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
      await driver.waitFor(find.text('Upgrader Example'));
      await driver.waitFor(find.text('Update App?'));
      await driver.waitFor(find.text('Would you like to update it now?'));
      await driver.waitFor(find.text('Release Notes'));
      await driver.waitFor(find.text('IGNORE'));
      await driver.waitFor(find.text('LATER'));
      await driver.waitFor(find.text('UPDATE NOW'));
    });
  });
}
