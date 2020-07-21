/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';

class _UpgradeBase extends StatefulWidget {
  /// The appcast configuration ([AppcastConfiguration]) used by [Appcast].
  final AppcastConfiguration appcastConfig;

  /// The localized messages used for display in upgrader.
  final UpgraderMessages messages;

  /// Days until alerting user again after later.
  final int daysToAlertAgain;

  /// For debugging, always force the upgrade to be available.
  final bool debugDisplayAlways;

  /// For debugging, display the upgrade at least once once.
  final bool debugDisplayOnce;

  /// For debugging, display logging statements.
  final bool debugLogging;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onIgnore;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onLater;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onUpdate;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  /// Hide or show Ignore button on dialog (default: true)
  final bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  final bool showLater;

  /// Can alert dialog be dismissed on tap outside of the alert dialog. Not used by alert card. (default: false)
  final bool canDismissDialog;

  /// The country code that will override the system locale. Optional. Used only for iOS.
  final String countryCode;

  /// The minimum app version supported by this app. Earlier versions of this app
  /// will be forced to update to the current version. Optional.
  final String minAppVersion;

  _UpgradeBase({
    Key key,
    this.appcastConfig,
    this.messages,
    this.daysToAlertAgain = 3,
    this.debugDisplayAlways = false,
    this.debugDisplayOnce = false,
    this.debugLogging = false,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.client,
    this.showIgnore,
    this.showLater,
    this.canDismissDialog,
    this.countryCode,
    this.minAppVersion,
  }) : super(key: key) {
    if (appcastConfig != null) {
      Upgrader().appcastConfig = appcastConfig;
    }
    if (messages != null) {
      Upgrader().messages = messages;
    }
    if (client != null) {
      Upgrader().client = client;
    }
    if (daysToAlertAgain != null) {
      Upgrader().daysUntilAlertAgain = daysToAlertAgain;
    }
    if (debugDisplayAlways != null) {
      Upgrader().debugDisplayAlways = debugDisplayAlways;
    }
    if (debugDisplayOnce != null) {
      Upgrader().debugDisplayOnce = debugDisplayOnce;
    }
    if (debugLogging != null) {
      Upgrader().debugLogging = debugLogging;
    }
    if (onIgnore != null) {
      Upgrader().onIgnore = onIgnore;
    }
    if (onLater != null) {
      Upgrader().onLater = onLater;
    }
    if (onUpdate != null) {
      Upgrader().onUpdate = onUpdate;
    }
    if (showIgnore != null) {
      Upgrader().showIgnore = showIgnore;
    }
    if (showLater != null) {
      Upgrader().showLater = showLater;
    }
    if (canDismissDialog != null) {
      Upgrader().canDismissDialog = canDismissDialog;
    }
    if (countryCode != null) {
      Upgrader().countryCode = countryCode;
    }
    if (minAppVersion != null) {
      Upgrader().minAppVersion = minAppVersion;
    }
  }

  Widget build(BuildContext context, _UpgradeBaseState state) {
    return null;
  }

  @override
  _UpgradeBaseState createState() => _UpgradeBaseState();
}

class _UpgradeBaseState extends State<_UpgradeBase> {
  bool rebuildNeeded = false;

  @override
  Widget build(BuildContext context) {
    return widget.build(context, this);
  }

  void forceUpdateState() {
    setState(() {
      rebuildNeeded = true;
    });
  }
}

/// A widget to display the upgrade card.
class UpgradeCard extends _UpgradeBase {
  /// The empty space that surrounds the card.
  ///
  /// The default margin is 4.0 logical pixels on all sides:
  /// `EdgeInsets.all(4.0)`.
  final EdgeInsetsGeometry margin;

  UpgradeCard({
    this.margin = const EdgeInsets.all(4.0),
    Key key,
    AppcastConfiguration appcastConfig,
    UpgraderMessages messages,
    int daysToAlertAgain,
    bool debugAlwaysUpgrade,
    bool debugDisplayOnce,
    bool debugLogging,
    BoolCallback onIgnore,
    BoolCallback onLater,
    BoolCallback onUpdate,
    http.Client client,
    bool showIgnore,
    bool showLater,
    bool canDismissDialog,
    String countryCode,
    String minAppVersion,
  }) : super(
          key: key,
          appcastConfig: appcastConfig,
          messages: messages,
          daysToAlertAgain: daysToAlertAgain,
          debugDisplayAlways: debugAlwaysUpgrade,
          debugDisplayOnce: debugDisplayOnce,
          debugLogging: debugLogging,
          onIgnore: onIgnore,
          onLater: onLater,
          onUpdate: onUpdate,
          client: client,
          showIgnore: showIgnore,
          showLater: showLater,
          canDismissDialog: canDismissDialog,
          countryCode: countryCode,
          minAppVersion: minAppVersion,
        );

  @override
  Widget build(BuildContext context, _UpgradeBaseState state) {
    if (Upgrader().debugLogging) {
      print('UpgradeCard: build UpgradeCard');
    }

    return FutureBuilder(
        future: Upgrader().initialize(),
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done) {
            assert(Upgrader().messages != null);
            if (Upgrader().shouldDisplayUpgrade()) {
              if (Upgrader().debugLogging) {
                print('UpgradeCard: will display');
              }
              return Card(
                  color: Colors.white,
                  margin: margin,
                  child: _AlertStyleWidget(
                      title: Text(
                          Upgrader().messages.message(UpgraderMessage.title)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(Upgrader().message()),
                          Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(Upgrader()
                                  .messages
                                  .message(UpgraderMessage.prompt))),
                        ],
                      ),
                      actions: <Widget>[
                        if (Upgrader().showIgnore)
                          FlatButton(
                              child: Text(Upgrader()
                                  .messages
                                  .message(UpgraderMessage.buttonTitleIgnore)),
                              onPressed: () {
                                // Save the date/time as the last time alerted.
                                Upgrader().saveLastAlerted();

                                Upgrader().onUserIgnored(context, false);
                                state.forceUpdateState();
                              }),
                        if (Upgrader().showLater)
                          FlatButton(
                              child: Text(Upgrader()
                                  .messages
                                  .message(UpgraderMessage.buttonTitleLater)),
                              onPressed: () {
                                // Save the date/time as the last time alerted.
                                Upgrader().saveLastAlerted();

                                Upgrader().onUserLater(context, false);
                                state.forceUpdateState();
                              }),
                        FlatButton(
                            child: Text(Upgrader()
                                .messages
                                .message(UpgraderMessage.buttonTitleUpdate)),
                            onPressed: () {
                              // Save the date/time as the last time alerted.
                              Upgrader().saveLastAlerted();

                              Upgrader().onUserUpdated(context, false);
                              state.forceUpdateState();
                            }),
                      ]));
            } else {
              if (Upgrader().debugLogging) {
                print('UpgradeCard: will not display');
              }
            }
          }
          return Container(width: 0.0, height: 0.0);
        });
  }
}

/// A widget to display the upgrade dialog.
class UpgradeAlert extends _UpgradeBase {
  /// The [child] contained by the widget.
  final Widget child;

  UpgradeAlert({
    Key key,
    AppcastConfiguration appcastConfig,
    UpgraderMessages messages,
    this.child,
    int daysToAlertAgain,
    bool debugAlwaysUpgrade,
    bool debugDisplayOnce,
    bool debugLogging,
    BoolCallback onIgnore,
    BoolCallback onLater,
    BoolCallback onUpdate,
    http.Client client,
    bool showIgnore,
    bool showLater,
    bool canDismissDialog,
    String countryCode,
    String minAppVersion,
  }) : super(
          key: key,
          appcastConfig: appcastConfig,
          messages: messages,
          daysToAlertAgain: daysToAlertAgain,
          debugDisplayAlways: debugAlwaysUpgrade,
          debugDisplayOnce: debugDisplayOnce,
          debugLogging: debugLogging,
          onIgnore: onIgnore,
          onLater: onLater,
          onUpdate: onUpdate,
          client: client,
          showIgnore: showIgnore,
          showLater: showLater,
          canDismissDialog: canDismissDialog,
          countryCode: countryCode,
          minAppVersion: minAppVersion,
        );

  @override
  Widget build(BuildContext context, _UpgradeBaseState state) {
    if (Upgrader().debugLogging) {
      print('upgrader: build UpgradeAlert');
    }

    return FutureBuilder(
        future: Upgrader().initialize(),
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done) {
            Upgrader().checkVersion(context: context);
          }
          return child;
        });
  }
}

class _AlertStyleWidget extends StatelessWidget {
  /// The (optional) content of the dialog is displayed in the center of the
  /// dialog in a lighter font.
  ///
  /// Typically, this is a [ListView] containing the contents of the dialog.
  /// Using a [ListView] ensures that the contents can scroll if they are too
  /// big to fit on the display.
  final Widget content;

  /// The (optional) set of actions that are displayed at the bottom of the
  /// dialog.
  ///
  /// Typically this is a list of [FlatButton] widgets.
  ///
  /// These widgets will be wrapped in a [ButtonBar], which introduces 8 pixels
  /// of padding on each side.
  ///
  /// If the [title] is not null but the [content] _is_ null, then an extra 20
  /// pixels of padding is added above the [ButtonBar] to separate the [title]
  /// from the [actions].
  final List<Widget> actions;

  /// The (optional) title of the dialog is displayed in a large font at the top
  /// of the dialog.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  const _AlertStyleWidget({
    Key key,
    @required this.content,
    @required this.actions,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final children = <Widget>[];
    const semanticLabel = 'semanticLabel';
    final EdgeInsetsGeometry titlePadding = null;
    final EdgeInsetsGeometry contentPadding =
        const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0);

    var label = semanticLabel;

    if (title != null) {
      children.add(Padding(
        padding: titlePadding ??
            EdgeInsets.fromLTRB(24.0, 24.0, 24.0, content == null ? 20.0 : 0.0),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.headline6,
          child: Semantics(child: title, namesRoute: true),
        ),
      ));
    } else {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.fuchsia) {
        label = semanticLabel ??
            MaterialLocalizations.of(context)?.alertDialogLabel;
      }
    }

    if (content != null) {
      children.add(Flexible(
        child: Padding(
          padding: contentPadding,
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.subtitle1,
            child: content,
          ),
        ),
      ));
    }

    if (actions != null) {
      children.add(
        ButtonBar(
          children: actions,
        ),
      );
    }

    Widget dialogChild = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (label != null) {
      dialogChild =
          Semantics(namesRoute: true, label: label, child: dialogChild);
    }

    return dialogChild;
  }
}
