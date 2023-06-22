/*
 * Copyright (c) 2018-2023 Larry Aasen. All rights reserved.
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
  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) => widget.build(context, this);

  Future<bool> initialize() => widget.upgrader.initialize();

  void forceUpdateState() => setState(() {});
}
