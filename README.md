# Upgrader

Flutter package for prompting users to upgrade when there is a newer version of the app in the store.

[![Build Status](https://travis-ci.org/larryaasen/upgrader.svg?branch=master)](https://travis-ci.org/larryaasen/upgrader) [![codecov](https://codecov.io/gh/larryaasen/upgrader/branch/master/graph/badge.svg)](https://codecov.io/gh/larryaasen/upgrader) [![pub package](https://img.shields.io/pub/v/upgrader.svg)](https://pub.dartlang.org/packages/upgrader)

A simple prompt widget is displayed when a newer app version is availabe
in the store.

## Example

Just wrap your body widget in the UpgradeAlert widget. It will handle the rest.
```dart
import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
          appBar: AppBar(
            title: Text('Upgrader Example'),
          ),
          body: UpgradeAlert(
            child: Center(child: Text('Checking...')),
          )
      ),
    );
  }
}
```

## Screenshot

![image](screenshots/example1.png)

## Customization

The UpgradeAlert widget can be customized... 

## iTunes Search API

There is a class in this Flutter package used by the UpgradeAlert widget to download app details 
from the
[iTunes Serach API](https://affiliate.itunes.apple.com/resources/documentation/itunes-store-web-service-search-api).
The class ITunesSearchAPI can be used standalone with the
UpgradeAlert widget to query iTunes for app details.
```dart
final iTunes = ITunesSearchAPI();
final results = await iTunes.lookupURLByBundleId('com.google.Maps');
```

## Contributing
All [comments](https://github.com/larryaasen/upgrader/issues) and [pull requests](https://github.com/larryaasen/upgrader/pulls) are welcome.