/*
 * Copyright (c) 2020 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upgrader/upgrader.dart';

void main() {
  testWidgets('test UpgraderMessages context', (WidgetTester tester) async {
    final messages = UpgraderMessages();
    expect(messages, isNotNull);

    var expectationMet = false;
    var widget = Text('Tester');

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
    expect(messages.title, '¿Actualizar la aplicación?');
  });
}
