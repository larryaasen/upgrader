/*
 * Copyright (c) 2018-2022 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

class UpgradeBase extends StatefulWidget {
  /// The upgraders used to configure the upgrade dialog.
  final Upgrader upgrader;

  const UpgradeBase(this.upgrader, {Key? key}) : super(key: key);

  Widget build(BuildContext context, UpgradeBaseState state) {
    return Container();
  }

  @override
  UpgradeBaseState createState() => UpgradeBaseState();
}

class UpgradeBaseState extends State<UpgradeBase> {
  Future<bool> get initialized => widget.upgrader.initialize();

  @override
  Widget build(BuildContext context) => widget.build(context, this);

  void forceUpdateState() {
    setState(() {});
  }
}
