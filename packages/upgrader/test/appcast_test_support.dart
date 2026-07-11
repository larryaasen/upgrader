import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upgrader/upgrader.dart';

Future<File> getTestFile({String filePath = 'test/testappcast.xml'}) async {
  var testFile = File(filePath);
  final exists = await testFile.exists();
  if (!exists) {
    testFile = File('testappcast.xml');
  }
  return testFile;
}

http.Client setupMockClient({String filePath = 'test/testappcast.xml'}) {
  return MockClient((http.Request request) async {
    if (request.url.toString() == 'https://sparkle-project.org/test/testappcast.xml') {
      final testFile = await getTestFile(filePath: filePath);
      final contents = await testFile.readAsString();
      return http.Response.bytes(utf8.encode(contents), 200);
    }
    return http.Response('', 400);
  });
}

class TestAppcast extends Appcast {
  TestAppcast({super.client, required super.osVersion, super.currentAppVersion, super.upgraderPlatform});

  Future<List<AppcastItem>?> parseAppcastItemsFromFile(File file) async {
    final contents = await file.readAsString();
    return parseAppcastItems(contents);
  }
}
