/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// A widget to display the upgrade dialog.
class UpgradeAlert extends UpgradeBase {
  /// The [child] contained by the widget.
  final Widget? child;

  //A widget for showing the dialog's content (should include the Title and the Message)
  final Content? content;

  /// The color of the modal barrier that darkens everything below the dialog.
  final Color? barrierColor;

  /// Whether to use the safe area of the device.
  final bool useSafeArea;

  /// Creates a new [UpgradeAlert].
  UpgradeAlert({
    Key? key,
    Upgrader? upgrader,
    this.child,
    this.navigatorKey,
    this.content,
    this.barrierColor,
    this.useSafeArea = true,
  }) : super(upgrader ?? Upgrader.sharedInstance, key: key);

  /// For use by the Router architecture as part of the RouterDelegate.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (upgrader.debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    return StreamBuilder(
      initialData: state.widget.upgrader.evaluationReady,
      stream: state.widget.upgrader.evaluationStream,
      builder:
          (BuildContext context, AsyncSnapshot<UpgraderEvaluateNeed> snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data != null &&
            snapshot.data!) {
          if (upgrader.debugLogging) {
            print("upgrader: need to evaluate version");
          }

          final checkContext =
              navigatorKey != null && navigatorKey!.currentContext != null
                  ? navigatorKey!.currentContext!
                  : context;
          upgrader.checkVersion(
            context: checkContext,
            content: content,
            barrierColor: barrierColor,
            useSafeArea: useSafeArea,
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
