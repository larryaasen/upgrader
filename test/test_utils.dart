// Copyright (c) 2024 Larry Aasen. All rights reserved.

import 'package:flutter/material.dart';

Widget wrapper(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
      appBar: AppBar(title: const Text('Upgrader test')),
    ),
  );
}
