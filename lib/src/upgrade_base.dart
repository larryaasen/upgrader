/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';

class UpgradeBase extends StatefulWidget {
  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  final AppcastConfiguration? appcastConfig;

  /// The localized messages used for display in upgrader.
  final UpgraderMessages? messages;

  /// For debugging, always force the upgrade to be available.
  final bool? debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  final bool? debugDisplayOnce;

  /// For debugging, display logging statements.
  final bool? debugLogging;

  /// Duration until alerting user again after later.
  Duration get durationToAlertAgain => Upgrader().durationUntilAlertAgain;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onIgnore;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onLater;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onUpdate;

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Not used by [UpgradeCard].
  final BoolCallback? shouldPopScope;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client? client;

  /// Hide or show Ignore button on dialog (default: true)
  final bool? showIgnore;

  /// Hide or show Later button on dialog (default: true)
  final bool? showLater;

  /// Hide or show release notes (default: true)
  final bool? showReleaseNotes;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by [UpgradeCard]. (default: false)
  final bool? canDismissDialog;

  /// The country code that will override the system locale. Optional. Used only for iOS.
  final String? countryCode;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  final String? minAppVersion;

  /// The upgrade dialog style. Optional. Used only on UpgradeAlert. (default: material)
  final UpgradeDialogStyle? dialogStyle;

  const UpgradeBase({
    Key? key,
    this.appcastConfig,
    this.messages,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    Duration? durationToAlertAgain = const Duration(days: 3),
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.client,
    this.showIgnore,
    this.showLater,
    this.showReleaseNotes,
    this.canDismissDialog,
    this.countryCode,
    this.minAppVersion,
    this.dialogStyle = UpgradeDialogStyle.material,
  }) : super(key: key);

  Widget? build(BuildContext context, UpgradeBaseState state) {
    return null;
  }

  @override
  UpgradeBaseState createState() => UpgradeBaseState();
}

class UpgradeBaseState extends State<UpgradeBase> {
  Future<bool> get initialized => Upgrader().initialize();

  @override
  void initState() {
    super.initState();
    if (widget.appcastConfig != null) {
      Upgrader().appcastConfig = widget.appcastConfig;
    }
    if (widget.messages != null) {
      Upgrader().messages = widget.messages;
    }
    if (widget.client != null) {
      Upgrader().client = widget.client;
    }
    if (widget.debugDisplayAlways != null) {
      Upgrader().debugDisplayAlways = widget.debugDisplayAlways!;
    }
    if (widget.debugDisplayOnce != null) {
      Upgrader().debugDisplayOnce = widget.debugDisplayOnce!;
    }
    if (widget.debugLogging != null) {
      Upgrader().debugLogging = widget.debugLogging!;
    }
    Upgrader().durationUntilAlertAgain = widget.durationToAlertAgain;
    if (widget.onIgnore != null) {
      Upgrader().onIgnore = widget.onIgnore;
    }
    if (widget.onLater != null) {
      Upgrader().onLater = widget.onLater;
    }
    if (widget.onUpdate != null) {
      Upgrader().onUpdate = widget.onUpdate;
    }
    if (widget.shouldPopScope != null) {
      Upgrader().shouldPopScope = widget.shouldPopScope;
    }
    if (widget.showIgnore != null) {
      Upgrader().showIgnore = widget.showIgnore!;
    }
    if (widget.showLater != null) {
      Upgrader().showLater = widget.showLater!;
    }
    if (widget.showReleaseNotes != null) {
      Upgrader().showReleaseNotes = widget.showReleaseNotes!;
    }
    if (widget.canDismissDialog != null) {
      Upgrader().canDismissDialog = widget.canDismissDialog!;
    }
    if (widget.countryCode != null) {
      Upgrader().countryCode = widget.countryCode;
    }
    if (widget.minAppVersion != null) {
      Upgrader().minAppVersion = widget.minAppVersion;
    }
    if (widget.dialogStyle != null) {
      Upgrader().dialogStyle = widget.dialogStyle;
    }
    Upgrader().initialize();
  }

  @override
  Widget build(BuildContext context) => widget.build(context, this)!;

  void forceUpdateState() => setState(() {});
}
