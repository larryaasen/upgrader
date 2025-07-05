// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Widget wrapper(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
      appBar: AppBar(title: const Text('Upgrader test')),
    ),
  );
}

Widget cupertinoWrapper(Widget child) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Upgrader test'),
      ),
      child: child,
    ),
  );
}
