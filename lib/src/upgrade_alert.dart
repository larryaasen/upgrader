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

  /// Hide or show Prompt label on the dialog (default: true)
  final bool showPrompt;

  /// Hide or show Ignore button on the dialog (default: true)
  final bool showIgnore;

  /// Hide or show Later button on the dialog (default: true)
  final bool showLater;

  /// Hide or show release notes on the dialog (default: true)
  final bool showReleaseNotes;

  /// The text style for the cupertino dialog buttons. Used only for
  /// [UpgradeDialogStyle.cupertino]. Optional.
  final TextStyle? cupertinoButtonTextStyle;

  /// The [Key] assigned to the dialog when it is shown. Optional.
  final GlobalKey? dialogKey;

  /// Usually not needed.
  ///
  /// In `MaterialApp.builder`, the dialog is shown above the whole app, so you
  /// don't need this key.
  ///
  /// Pass the app's navigator key only when [UpgradeAlert] wraps the whole app
  /// (outside `MaterialApp`) or has no [child]. The dialog is then shown on that
  /// navigator.
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The [child] widget displayed behind the upgrade dialog. If null, a
  /// [SizedBox.shrink] is used.
  final Widget? child;

  @override
  UpgradeAlertState createState() => UpgradeAlertState();
}

/// The [UpgradeAlert] widget state.
class UpgradeAlertState extends State<UpgradeAlert>
    with WidgetsBindingObserver {
  /// Is the alert dialog being displayed right now?
  bool displayed = false;
  bool _useDialogNavigator = false;
  final _dialogNavigatorVisible = ValueNotifier<bool>(false);
  final GlobalKey<NavigatorState> _dialogNavigatorKey =
      GlobalKey<NavigatorState>();
  final GlobalKey _appKey = GlobalKey();
  late final _dialogNavigatorObserver = _DialogNavigatorObserver(
    onPush: _onDialogRoutePushed,
    onRemove: _onDialogRouteRemoved,
  );
  late final _appPopEntry = _ForwardingPopEntry(_popDialogNavigator);
  ModalRoute<dynamic>? _appPopEntryRoute;

  @override
  void initState() {
    super.initState();
    // Registered here so it runs before a descendant Router's back dispatcher.
    WidgetsBinding.instance.addObserver(this);
    widget.upgrader.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detachAppPopEntry();
    _appPopEntry.dispose();
    _dialogNavigatorVisible.dispose();
    super.dispose();
  }

  /// Forwards system back to the private dialog navigator.
  @override
  Future<bool> didPopRoute() async {
    if (!_hasDialogRoute) {
      return false;
    }
    await _popDialogNavigator();
    // Consume back even when the dialog refuses to pop, so it never reaches the app.
    return true;
  }

  bool get _hasDialogRoute =>
      _dialogNavigatorKey.currentState?.canPop() ?? false;

  Future<void> _popDialogNavigator() async {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: back forwarded to the dialog navigator');
    }
    await _dialogNavigatorKey.currentState?.maybePop();
  }

  void _onDialogRoutePushed() {
    if (_hasDialogRoute) {
      _attachAppPopEntry();
    }
  }

  void _onDialogRouteRemoved(Route<dynamic> route) {
    if (_hasDialogRoute) {
      return;
    }
    _detachAppPopEntry();
    final exited = route is TransitionRoute ? route.completed : Future.value();
    exited.whenComplete(() {
      if (mounted && !_hasDialogRoute) {
        _dialogNavigatorVisible.value = false;
      }
    });
  }

  /// Stops back from popping the app's page under the dialog.
  void _attachAppPopEntry() {
    final route = _appTopRoute();
    final previous = _appPopEntryRoute;
    if (route == previous) {
      return;
    }
    // Set before (un)registering: it notifies the listener that calls this again.
    _appPopEntryRoute = route;
    previous?.unregisterPopEntry(_appPopEntry);
    route?.registerPopEntry(_appPopEntry);
  }

  void _detachAppPopEntry() {
    final route = _appPopEntryRoute;
    _appPopEntryRoute = null;
    route?.unregisterPopEntry(_appPopEntry);
  }

  ModalRoute<dynamic>? _appTopRoute() {
    final navigator = widget.navigatorKey?.currentState ?? _findAppNavigator();
    Route<dynamic>? top;
    // NavigatorState has no public top route; a predicate that matches first pops nothing.
    navigator?.popUntil((route) {
      top = route;
      return true;
    });
    return top is ModalRoute ? top as ModalRoute<dynamic> : null;
  }

  NavigatorState? _findAppNavigator() {
    NavigatorState? found;
    void visit(Element element) {
      if (found != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;
        return;
      }
      element.visitChildren(visit);
    }

    _appKey.currentContext?.visitChildElements(visit);
    return found;
  }

  /// Returns the context the dialog should be shown from, mounting the private
  /// dialog navigator first when it is used.
  Future<BuildContext> _dialogContext(BuildContext fallback) async {
    if (!_useDialogNavigator) {
      return fallback;
    }
    _dialogNavigatorVisible.value = true;
    if (_dialogNavigatorKey.currentContext == null) {
      await WidgetsBinding.instance.endOfFrame;
    }
    return _dialogNavigatorKey.currentContext ?? fallback;
  }

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    if (widget.upgrader.state.debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    // Above the app's navigator (e.g. MaterialApp.builder) later routes would
    // cover the dialog, so it is shown on a private navigator stacked on top.
    _useDialogNavigator = widget.child != null &&
        Navigator.maybeOf(context) == null &&
        Localizations.maybeLocaleOf(context) != null;

    final alert = StreamBuilder(
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

    if (!_useDialogNavigator) {
      return alert;
    }

    return Stack(
      fit: StackFit.passthrough,
      children: [
        NotificationListener<NavigationNotification>(
          onNotification: (_) {
            if (_hasDialogRoute) {
              _attachAppPopEntry();
            }
            return false;
          },
          child: KeyedSubtree(key: _appKey, child: alert),
        ),
        Positioned.fill(
          child: ValueListenableBuilder<bool>(
            valueListenable: _dialogNavigatorVisible,
            builder: (context, visible, navigator) =>
                visible ? navigator! : const SizedBox.shrink(),
            child: NotificationListener<NavigationNotification>(
              // Drop its "can't pop", or Android back would close the app.
              onNotification: (notification) => !notification.canHandlePop,
              child: HeroControllerScope.none(
                child: Navigator(
                  key: _dialogNavigatorKey,
                  observers: [_dialogNavigatorObserver],
                  onGenerateRoute: (settings) => PageRouteBuilder<void>(
                    settings: settings,
                    opaque: false,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SizedBox.shrink(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

      Future.delayed(Duration.zero, () async {
        // ignore: use_build_context_synchronously
        final dialogContext = await _dialogContext(context);
        if (!mounted) return;
        showTheDialog(
          key: widget.dialogKey ?? const Key('upgrader_alert_dialog'),
          // ignore: use_build_context_synchronously
          context: dialogContext,
          title: appMessages.message(UpgraderMessage.title),
          message: widget.upgrader.body(appMessages),
          releaseNotes:
              shouldDisplayReleaseNotes ? widget.upgrader.releaseNotes : null,
          barrierDismissible: widget.barrierDismissible,
          messages: appMessages,
        );
        // An override may show nothing, which must not leave the barrier up.
        if (_useDialogNavigator && !_hasDialogRoute) {
          _dialogNavigatorVisible.value = false;
        }
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
    displayed = false;
    Navigator.of(context).pop();
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
  /// Will return the result from [shouldPopScope] if it is not null, otherwise it will return [UpgradeAlert.barrierDismissible].
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

    return widget.barrierDismissible;
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

class _DialogNavigatorObserver extends NavigatorObserver {
  _DialogNavigatorObserver({required this.onPush, required this.onRemove});

  final VoidCallback onPush;
  final void Function(Route<dynamic> route) onRemove;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onPush();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onRemove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      onRemove(route);
}

/// Blocks a pop on the route it is registered with and reports it instead.
class _ForwardingPopEntry extends PopEntry<Object?> {
  _ForwardingPopEntry(this.onBlockedPop);

  final VoidCallback onBlockedPop;

  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(false);

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) {
      onBlockedPop();
    }
  }

  void dispose() => canPopNotifier.dispose();
}
