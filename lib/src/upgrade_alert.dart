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

  late Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _initUpgrader();
  }

  @override
  void dispose() {
    _upgrader.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant UpgradeAlert oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.upgrader.minAppVersion != oldWidget.upgrader.minAppVersion) {
      oldWidget.upgrader.dispose();
      _initUpgrader();
    }
  }

  void _initUpgrader() {
    _upgrader = widget.upgrader;
    _upgrader.initialize();
  }

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    if (_upgrader.state.debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    return StreamBuilder(
      // The key is necessary until https://github.com/flutter/flutter/issues/64916 is fixed.
      key: ValueKey(_upgrader.hashCode),
      initialData: _upgrader.state,
      stream: _upgrader.stateStream,
      builder: (BuildContext context, AsyncSnapshot<UpgraderState> snapshot) {
        if ((snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) &&
            snapshot.data != null) {
          final upgraderState = snapshot.data!;
          if (upgraderState.versionInfo != null) {
            if (_upgrader.state.debugLogging) {
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
    final shouldDisplay = _upgrader.shouldDisplayUpgrade();
    if (_upgrader.state.debugLogging) {
      print('upgrader: shouldDisplayReleaseNotes: $shouldDisplayReleaseNotes');
    }
    if (shouldDisplay) {
      displayed = true;
      final appMessages = _upgrader.determineMessages(context);

      Future.delayed(Duration.zero, () {
        showTheDialog(
          key: widget.dialogKey ?? const Key('upgrader_alert_dialog'),
          // ignore: use_build_context_synchronously
          context: context,
          title: appMessages.message(UpgraderMessage.title),
          message: _upgrader.body(appMessages),
          releaseNotes:
              shouldDisplayReleaseNotes ? _upgrader.releaseNotes : null,
          barrierDismissible: widget.barrierDismissible,
          messages: appMessages,
        );
      });
    }
  }

  void onUserIgnored(BuildContext context, bool shouldPop) {
    if (_upgrader.state.debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onIgnore?.call() ?? true;

    if (doProcess) {
      _upgrader.saveIgnored();
    }

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserLater(BuildContext context, bool shouldPop) {
    if (_upgrader.state.debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    widget.onLater?.call();

    if (shouldPop) {
      popNavigator(context);
    }
  }

  void onUserUpdated(BuildContext context, bool shouldPop) {
    if (_upgrader.state.debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onUpdate?.call() ?? true;

    if (doProcess) {
      _upgrader.sendUserToAppStore();
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
      widget.showReleaseNotes && (_upgrader.releaseNotes?.isNotEmpty ?? false);

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
    if (_upgrader.state.debugLogging) {
      print('upgrader: showTheDialog title: $title');
      print('upgrader: showTheDialog message: $message');
      print('upgrader: showTheDialog releaseNotes: $releaseNotes');
    }

    // Save the date/time as the last time alerted.
    _upgrader.saveLastAlerted();

    showDialog(
      barrierDismissible: barrierDismissible,
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: onCanPop(),
          onPopInvokedWithResult: (didPop, result) {
            if (_upgrader.state.debugLogging) {
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
      },
    );
  }

  /// Determines if the dialog blocks the current route from being popped.
  /// Will return the result from [shouldPopScope] if it is not null, otherwise it will return false.
  bool onCanPop() {
    if (_upgrader.state.debugLogging) {
      print('upgrader: onCanPop called');
    }
    if (widget.shouldPopScope != null) {
      final should = widget.shouldPopScope!();
      if (_upgrader.state.debugLogging) {
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
    final isBlocked = _upgrader.blocked();
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
            Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(messages.message(UpgraderMessage.prompt) ?? '')),
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
        onPressed: () => onUserUpdated(context, !_upgrader.blocked()),
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
