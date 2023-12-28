/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'upgrade_messages.dart';
import 'upgrader.dart';

/// There are two different dialog styles: Cupertino and Material
enum UpgradeDialogStyle { cupertino, material }

/// A widget to display the upgrade dialog.
class UpgradeAlert extends StatefulWidget {
  /// Creates a new [UpgradeAlert].
  UpgradeAlert({
    super.key,
    Upgrader? upgrader,
    this.canDismissDialog = false,
    this.dialogStyle = UpgradeDialogStyle.material,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.cupertinoButtonTextStyle,
    this.navigatorKey,
    this.child,
  }) : upgrader = upgrader ?? Upgrader.sharedInstance;

  /// The upgraders used to configure the upgrade dialog.
  final Upgrader upgrader;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by [UpgradeCard]. (default: false)
  final bool canDismissDialog;

  /// The upgrade dialog style. Used only on UpgradeAlert. (default: material)
  final UpgradeDialogStyle dialogStyle;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onIgnore;

  /// Called when the later button is tapped or otherwise activated.
  final BoolCallback? onLater;

  /// Called when the update button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onUpdate;

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped.
  final BoolCallback? shouldPopScope;

  /// Hide or show Ignore button on dialog (default: true)
  final bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  final bool showLater;

  /// Hide or show release notes (default: true)
  final bool showReleaseNotes;

  /// The text style for the cupertino dialog buttons. Used only for
  /// [UpgradeDialogStyle.cupertino]. Optional.
  final TextStyle? cupertinoButtonTextStyle;

  /// For use by the Router architecture as part of the RouterDelegate.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The [child] contained by the widget.
  final Widget? child;

  static bool _displayed = false;

  @override
  UpgradeAlertBaseState createState() => UpgradeAlertBaseState();

  Widget build(BuildContext context) {
    if (upgrader.debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    return StreamBuilder(
      initialData: upgrader.evaluationReady,
      stream: upgrader.evaluationStream,
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
          checkVersion(context: checkContext);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  /// Will show the alert dialog when it should be dispalyed.
  /// Only called by [UpgradeAlert] and not used by [UpgradeCard].
  void checkVersion({required BuildContext context}) {
    if (_displayed) return;

    final shouldDisplay = upgrader.shouldDisplayUpgrade();
    if (upgrader.debugLogging) {
      print('upgrader: shouldDisplayReleaseNotes: shouldDisplayReleaseNotes');
    }
    if (shouldDisplay) {
      _displayed = true;
      final appMessages = upgrader.determineMessages(context);

      Future.delayed(const Duration(milliseconds: 0), () {
        showTheDialog(
          context: context,
          title: appMessages.message(UpgraderMessage.title),
          message: upgrader.body(appMessages),
          releaseNotes:
              shouldDisplayReleaseNotes ? upgrader.releaseNotes : null,
          canDismissDialog: canDismissDialog,
          messages: appMessages,
        );
      });
    }
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (upgrader.debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    final doProcess = onIgnore?.call() ?? true;

    if (doProcess) {
      upgrader.saveIgnored();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (upgrader.debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    onLater?.call();

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (upgrader.debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    final doProcess = onUpdate?.call() ?? true;

    if (doProcess) {
      upgrader.sendUserToAppStore();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void popNavigator(BuildContext context) {
    Navigator.of(context).pop();
    _displayed = false;
  }

  bool get shouldDisplayReleaseNotes =>
      showReleaseNotes && (upgrader.releaseNotes?.isNotEmpty ?? false);

  void showTheDialog({
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool canDismissDialog,
    required UpgraderMessages messages,
  }) {
    if (upgrader.debugLogging) {
      print('upgrader: showTheDialog title: $title');
      print('upgrader: showTheDialog message: $message');
      print('upgrader: showTheDialog releaseNotes: $releaseNotes');
    }

    // Save the date/time as the last time alerted.
    upgrader.saveLastAlerted();

    showDialog(
      barrierDismissible: canDismissDialog,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
            onWillPop: () async => onWillPop(),
            child: alertDialog(
              title ?? '',
              message,
              releaseNotes,
              context,
              dialogStyle == UpgradeDialogStyle.cupertino,
              messages,
            ));
      },
    );
  }

  /// Called when the user taps outside of the dialog and [canDismissDialog]
  /// is false. Also called when the back button is pressed. Return true for
  /// the screen to be popped. Defaults to false.
  bool onWillPop() {
    if (upgrader.debugLogging) {
      print('upgrader: onWillPop called');
    }
    if (shouldPopScope != null) {
      final should = shouldPopScope!();
      if (upgrader.debugLogging) {
        print('upgrader: shouldPopScope=$should');
      }
      return should;
    }

    return false;
  }

  Widget alertDialog(String title, String message, String? releaseNotes,
      BuildContext context, bool cupertino, UpgraderMessages messages) {
    // If installed version is below minimum app version, or is a critical update,
    // disable ignore and later buttons.
    final isBlocked = upgrader.blocked();
    final showIgnore = isBlocked ? false : this.showIgnore;
    final showLater = isBlocked ? false : this.showLater;

    Widget? notes;
    if (releaseNotes != null) {
      notes = Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cupertino
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: <Widget>[
              Text(messages.message(UpgraderMessage.releaseNotes) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(releaseNotes),
            ],
          ));
    }
    final textTitle = Text(title, key: const Key('upgrader.dialog.title'));
    final content = Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment:
              cupertino ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(message),
            Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(messages.message(UpgraderMessage.prompt) ?? '')),
            if (notes != null) notes,
          ],
        )));
    final actions = <Widget>[
      if (showIgnore)
        button(cupertino, messages.message(UpgraderMessage.buttonTitleIgnore),
            context, () => onUserIgnored(context, true)),
      if (showLater)
        button(cupertino, messages.message(UpgraderMessage.buttonTitleLater),
            context, () => onUserLater(context, true)),
      button(cupertino, messages.message(UpgraderMessage.buttonTitleUpdate),
          context, () => onUserUpdated(context, !upgrader.blocked())),
    ];

    return cupertino
        ? CupertinoAlertDialog(
            title: textTitle, content: content, actions: actions)
        : AlertDialog(title: textTitle, content: content, actions: actions);
  }

  Widget button(bool cupertino, String? text, BuildContext context,
      VoidCallback? onPressed) {
    return cupertino
        ? CupertinoDialogAction(
            textStyle: cupertinoButtonTextStyle,
            onPressed: onPressed,
            child: Text(text ?? ''))
        : TextButton(onPressed: onPressed, child: Text(text ?? ''));
  }
}

class UpgradeAlertBaseState extends State<UpgradeAlert> {
  @override
  void initState() {
    super.initState();
    widget.upgrader.initialize();
  }

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) => widget.build(context);
}
