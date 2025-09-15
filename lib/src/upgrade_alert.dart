/*
 * Copyright (c) 2021-2024 Larry Aasen. All rights reserved.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'upgrade_messages.dart';
import 'upgrade_state.dart';
import 'upgrader.dart';

/// There are two different dialog styles: Cupertino and Material
enum UpgradeDialogStyle { cupertino, material }

/// A widget to display the upgrade dialog.
/// Override the [createState] method to provide a custom class
/// with overridden methods.
class UpgradeAlert extends StatefulWidget {
  /// Creates a new [UpgradeAlert].
  UpgradeAlert({
    super.key,
    Upgrader? upgrader,
    this.barrierDismissible = false,
    this.dialogStyle = UpgradeDialogStyle.material,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.shouldPopScope,
    this.showPrompt = true,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
    this.cupertinoButtonTextStyle,
    this.dialogKey,
    this.navigatorKey,
    this.child,
  }) : upgrader = upgrader ?? Upgrader.sharedInstance;

  /// The upgraders used to configure the upgrade dialog.
  final Upgrader upgrader;

  /// The `barrierDismissible` argument is used to indicate whether tapping on the
  /// barrier will dismiss the dialog. (default: false)
  final bool barrierDismissible;

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

  /// Called to determine if the dialog blocks the current route from being popped.
  final BoolCallback? shouldPopScope;

  /// Hide or show Prompt label on dialog (default: true)
  final bool showPrompt;

  /// Hide or show Ignore button on dialog (default: true)
  final bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  final bool showLater;

  /// Hide or show release notes (default: true)
  final bool showReleaseNotes;

  /// The text style for the cupertino dialog buttons. Used only for
  /// [UpgradeDialogStyle.cupertino]. Optional.
  final TextStyle? cupertinoButtonTextStyle;

  /// The [Key] assigned to the dialog when it is shown.
  final GlobalKey? dialogKey;

  /// For use by the Router architecture as part of the RouterDelegate.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The [child] contained by the widget.
  final Widget? child;

  @override
  UpgradeAlertState createState() => UpgradeAlertState();
}

/// The [UpgradeAlert] widget state.
class UpgradeAlertState extends State<UpgradeAlert> {
  /// Is the alert dialog being displayed right now?
  bool displayed = false;

  @override
  void initState() {
    super.initState();
    widget.upgrader.initialize();
  }

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    return StreamBuilder(
      initialData: widget.upgrader.state,
      stream: widget.upgrader.stateStream,
      builder: (BuildContext context, AsyncSnapshot<UpgraderState> snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data != null) {
          final upgraderState = snapshot.data!;
          if (upgraderState.versionInfo != null) {
            if (widget.upgrader.state.debugLogging) {
              print("upgrader: need to evaluate version");
            }

            if (!displayed) {
              final checkContext = widget.navigatorKey != null &&
                      widget.navigatorKey!.currentContext != null
                  ? widget.navigatorKey!.currentContext!
                  : context;
              checkVersion(context: checkContext);
            }
          }
        }
        return widget.child ?? const SizedBox.shrink();
      },
    );
  }

  /// Will show the alert dialog when it should be dispalyed.
  void checkVersion({required BuildContext context}) {
    final shouldDisplay = widget.upgrader.shouldDisplayUpgrade();
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: shouldDisplayReleaseNotes: $shouldDisplayReleaseNotes');
    }
    if (shouldDisplay) {
      displayed = true;
      final appMessages = widget.upgrader.determineMessages(context);

      Future.delayed(Duration.zero, () {
        showTheDialog(
          key: widget.dialogKey ?? const Key('upgrader_alert_dialog'),
          // ignore: use_build_context_synchronously
          context: context,
          title: appMessages.message(UpgraderMessage.title),
          message: widget.upgrader.body(appMessages),
          releaseNotes:
              shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
          barrierDismissible: widget.barrierDismissible,
          messages: appMessages,
        );
      });
    }
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onIgnore?.call() ?? true;

    if (doProcess) {
      widget.upgrader.saveIgnored();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    widget.onLater?.call();

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onUpdate?.call() ?? true;

    if (doProcess) {
      widget.upgrader.sendUserToAppStore();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void popNavigator(BuildContext context) {
    Navigator.of(context).pop();
    displayed = false;
  }

  bool get shouldDisplayReleaseNotes =>
      widget.showReleaseNotes &&
      (widget.upgrader.releaseNotes?.isNotEmpty ?? false);

  /// Show the alert dialog.
  void showTheDialog({
    Key? key,
    required BuildContext context,
    required String? title,
    required String message,
    required String? releaseNotes,
    required bool barrierDismissible,
    required UpgraderMessages messages,
  }) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: showTheDialog title: $title');
      print('upgrader: showTheDialog message: $message');
      print('upgrader: showTheDialog releaseNotes: $releaseNotes');
    }

    if (!context.mounted) {
      if (widget.upgrader.state.debugLogging) {
        print('upgrader: showTheDialog context not mounted - dialog not shown');
      }
      return;
    }

    // Save the date/time as the last time alerted.
    widget.upgrader.saveLastAlerted();

    // Detect if CupertinoApp is in the widget tree
    final isCupertinoApp =
        context.findAncestorWidgetOfExactType<CupertinoApp>() != null;

    dialogBuilder(BuildContext context) => PopScope(
          canPop: onCanPop(),
          onPopInvokedWithResult: (didPop, result) {
            if (widget.upgrader.state.debugLogging) {
              print('upgrader: showTheDialog onPopInvoked: $didPop');
            }
          },
          child: alertDialog(
            key,
            title ?? '',
            message,
            releaseNotes,
            context,
            widget.dialogStyle == UpgradeDialogStyle.cupertino,
            messages,
          ),
        );

    if (isCupertinoApp) {
      showCupertinoDialog(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: dialogBuilder,
      );
    } else {
      showDialog(
        barrierDismissible: barrierDismissible,
        context: context,
        builder: dialogBuilder,
      );
    }
  }

  /// Determines if the dialog blocks the current route from being popped.
  /// Will return the result from [shouldPopScope] if it is not null, otherwise it will return false.
  bool onCanPop() {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: onCanPop called');
    }
    if (widget.shouldPopScope != null) {
      final should = widget.shouldPopScope!();
      if (widget.upgrader.state.debugLogging) {
        print('upgrader: shouldPopScope=$should');
      }
      return should;
    }

    return false;
  }

  Widget alertDialog(
      Key? key,
      String title,
      String message,
      String? releaseNotes,
      BuildContext context,
      bool cupertino,
      UpgraderMessages messages) {
    // If installed version is below minimum app version, or is a critical update,
    // disable ignore and later buttons.
    final isBlocked = widget.upgrader.blocked();
    final showIgnore = isBlocked ? false : widget.showIgnore;
    final showLater = isBlocked ? false : widget.showLater;

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
            if (widget.showPrompt)
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(messages.message(UpgraderMessage.prompt) ?? ''),
              ),
            if (notes != null) notes,
          ],
        )));
    final actions = <Widget>[
      if (showIgnore)
        button(
          cupertino: cupertino,
          text: messages.message(UpgraderMessage.buttonTitleIgnore),
          context: context,
          onPressed: () => onUserIgnored(context, true),
          isDefaultAction: false,
        ),
      if (showLater)
        button(
          cupertino: cupertino,
          text: messages.message(UpgraderMessage.buttonTitleLater),
          context: context,
          onPressed: () => onUserLater(context, true),
          isDefaultAction: false,
        ),
      button(
        cupertino: cupertino,
        text: messages.message(UpgraderMessage.buttonTitleUpdate),
        context: context,
        onPressed: () => onUserUpdated(context, !widget.upgrader.blocked()),
        isDefaultAction: true,
      ),
    ];

    return cupertino
        ? CupertinoAlertDialog(
            key: key, title: textTitle, content: content, actions: actions)
        : AlertDialog(
            key: key, title: textTitle, content: content, actions: actions);
  }

  Widget button({
    required bool cupertino,
    String? text,
    required BuildContext context,
    VoidCallback? onPressed,
    bool isDefaultAction = false,
  }) {
    return cupertino
        ? CupertinoDialogAction(
            textStyle: widget.cupertinoButtonTextStyle,
            onPressed: onPressed,
            isDefaultAction: isDefaultAction,
            child: Text(text ?? ''))
        : TextButton(onPressed: onPressed, child: Text(text ?? ''));
  }
}
