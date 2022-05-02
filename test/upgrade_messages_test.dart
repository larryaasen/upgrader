/*
 * Copyright (c) 2020 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  test('testing UpgraderMessages valid', () async {
    expect(UpgraderMessages(), isNotNull);
    expect(() => UpgraderMessages(code: null), isNotNull);
    expect(() => UpgraderMessages(code: ''), throwsAssertionError);
    expect(() => UpgraderMessages(code: '0'), isNotNull);
  });

  testWidgets('test UpgraderMessages context', (WidgetTester tester) async {
    final messages = UpgraderMessages();
    expect(messages, isNotNull);

    var expectationMet = false;
    var widget = const Text('Tester');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final code = UpgraderMessages.findLanguageCode(context: context);
          expect(code, 'en');
          expectationMet = true;
          return MaterialApp(
            home: Material(
              child: Center(
                child: widget,
              ),
            ),
          );
        },
      ),
    );

    expect(find.byWidget(widget), findsOneWidget);
    expect(expectationMet, isTrue);
  });

  testWidgets('test UpgraderMessages es', (WidgetTester tester) async {
    final messages = UpgraderMessages(code: 'es');
    expect(messages, isNotNull);
    expect(messages.body,
        '¡Una nueva versión de {{appName}} está disponible! La versión {{currentAppStoreVersion}} ya está disponible-usted tiene {{currentInstalledVersion}}.');
    expect(messages.buttonTitleIgnore, 'IGNORAR');
    expect(messages.buttonTitleLater, 'MÁS TARDE');
    expect(messages.buttonTitleUpdate, 'ACTUALIZAR');
    expect(messages.prompt, '¿Le gustaría actualizar ahora?');
    expect(messages.releaseNotes, 'Notas De Lanzamiento');
    expect(messages.title, '¿Actualizar la aplicación?');
  });

  test('test UpgraderMessages unknown language code', () {
    final bb = UpgraderMessages(code: 'bb'); // unknown language code
    final en = UpgraderMessages(code: 'en'); // English language code

    expect(bb.message(UpgraderMessage.body), en.message(UpgraderMessage.body));
    expect(bb.message(UpgraderMessage.buttonTitleIgnore),
        en.message(UpgraderMessage.buttonTitleIgnore));
    expect(bb.message(UpgraderMessage.buttonTitleLater),
        en.message(UpgraderMessage.buttonTitleLater));
    expect(bb.message(UpgraderMessage.buttonTitleUpdate),
        en.message(UpgraderMessage.buttonTitleUpdate));
    expect(
        bb.message(UpgraderMessage.prompt), en.message(UpgraderMessage.prompt));
    expect(bb.message(UpgraderMessage.releaseNotes),
        en.message(UpgraderMessage.releaseNotes));
    expect(
        bb.message(UpgraderMessage.title), en.message(UpgraderMessage.title));
  });
}
