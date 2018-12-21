/*
 * Copyright (c) 2018 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'upgrader.dart';

class _UpgradeBase extends StatelessWidget {
  /// The ignore button title, which defaults to ```Ignore```
  final String buttonTitleIgnore;

  /// The later button title, which defaults to ```Later```
  final String buttonTitleLater;

  /// The update button title, which defaults to ```Update Now```
  final String buttonTitleUpdate;

  /// Days until alerting user again after later.
  final int daysToAlertAgain;

  /// For debugging, always force the upgrade to be available.
  final bool debugAlwaysUpgrade;

  /// Enable print statements for debugging.
  final bool debugEnabled;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onIgnore;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onLater;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback onUpdate;

  /// The call to action message, which defaults to: Would you like to update it now?
  final String prompt;

  /// The title of the alert dialog. Defaults to: Update App?
  final String title;

  /// Provide an HTTP Client that can be replaced for mock testing.
  final http.Client client;

  _UpgradeBase({
    Key key,
    this.buttonTitleIgnore,
    this.buttonTitleLater,
    this.buttonTitleUpdate,
    this.daysToAlertAgain = 3,
    this.debugAlwaysUpgrade = false,
    this.debugEnabled = false,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.prompt,
    this.title,
    this.client,
  }) : super(key: key) {
    if (this.buttonTitleIgnore != null) {
      Upgrader().buttonTitleIgnore = this.buttonTitleIgnore;
    }
    if (this.buttonTitleLater != null) {
      Upgrader().buttonTitleLater = this.buttonTitleLater;
    }
    if (this.buttonTitleUpdate != null) {
      Upgrader().buttonTitleUpdate = this.buttonTitleUpdate;
    }
    if (this.client != null) {
      Upgrader().client = this.client;
    }
    if (this.daysToAlertAgain != null) {
      Upgrader().daysUntilAlertAgain = this.daysToAlertAgain;
    }
    if (this.debugAlwaysUpgrade != null) {
      Upgrader().debugAlwaysUpgrade = this.debugAlwaysUpgrade;
    }
    if (this.debugEnabled != null) {
      Upgrader().debugEnabled = this.debugEnabled;
    }
    if (this.onIgnore != null) {
      Upgrader().onIgnore = this.onIgnore;
    }
    if (this.onLater != null) {
      Upgrader().onLater = this.onLater;
    }
    if (this.onUpdate != null) {
      Upgrader().onUpdate = this.onUpdate;
    }
    if (this.prompt != null) {
      Upgrader().prompt = this.prompt;
    }
    if (this.title != null) {
      Upgrader().title = this.title;
    }
  }

  @override
  Widget build(BuildContext context) {
    return null;
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
    String buttonTitleIgnore,
    String buttonTitleLater,
    String buttonTitleUpdate,
    int daysToAlertAgain,
    bool debugAlwaysUpgrade,
    bool debugEnabled,
    BoolCallback onIgnore,
    BoolCallback onLater,
    BoolCallback onUpdate,
    String prompt,
    String title,
    http.Client client,
  }) : super(
          key: key,
          buttonTitleIgnore: buttonTitleIgnore,
          buttonTitleLater: buttonTitleLater,
          buttonTitleUpdate: buttonTitleUpdate,
          daysToAlertAgain: daysToAlertAgain,
          debugAlwaysUpgrade: debugAlwaysUpgrade,
          debugEnabled: debugEnabled,
          onIgnore: onIgnore,
          onLater: onLater,
          onUpdate: onUpdate,
          prompt: prompt,
          title: title,
          client: client,
        );

  @override
  Widget build(BuildContext context) {
    if (Upgrader().debugEnabled) {
      print('upgrader: build UpgradeCard');
    }

    return FutureBuilder(
        future: Upgrader().initialize(),
        builder: (BuildContext context, AsyncSnapshot<bool> processed) {
          if (processed.connectionState == ConnectionState.done) {
            if (Upgrader().shouldDisplayUpgrade()) {
              return Card(
                  color: Colors.white,
                  margin: this.margin,
                  child: new _AlertStyleWidget(
                      title: Text(Upgrader().title),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(Upgrader().message()),
                          Padding(
                              padding: EdgeInsets.only(top: 15.0),
                              child: Text(Upgrader().prompt)),
                        ],
                      ),
                      actions: <Widget>[
                        FlatButton(
                            child: Text(Upgrader().buttonTitleIgnore),
                            onPressed: () =>
                                Upgrader().onUserIgnored(context, false)),
                        FlatButton(
                            child: Text(Upgrader().buttonTitleLater),
                            onPressed: () =>
                                Upgrader().onUserLater(context, false)),
                        FlatButton(
                            child: Text(Upgrader().buttonTitleUpdate),
                            onPressed: () =>
                                Upgrader().onUserUpdated(context, false)),
                      ]));
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
    String buttonTitleIgnore,
    String buttonTitleLater,
    String buttonTitleUpdate,
    this.child,
    int daysToAlertAgain,
    bool debugAlwaysUpgrade,
    bool debugEnabled,
    BoolCallback onIgnore,
    BoolCallback onLater,
    BoolCallback onUpdate,
    String prompt,
    String title,
    http.Client client,
  }) : super(
          key: key,
          buttonTitleIgnore: buttonTitleIgnore,
          buttonTitleLater: buttonTitleLater,
          buttonTitleUpdate: buttonTitleUpdate,
          daysToAlertAgain: daysToAlertAgain,
          debugAlwaysUpgrade: debugAlwaysUpgrade,
          debugEnabled: debugEnabled,
          onIgnore: onIgnore,
          onLater: onLater,
          onUpdate: onUpdate,
          prompt: prompt,
          title: title,
          client: client,
        );

  @override
  Widget build(BuildContext context) {
    if (Upgrader().debugEnabled) {
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
    final List<Widget> children = <Widget>[];
    String semanticLabel = 'semanticLabel';
    final EdgeInsetsGeometry titlePadding = null;
    final EdgeInsetsGeometry contentPadding =
        const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0);

    String label = semanticLabel;

    if (title != null) {
      children.add(Padding(
        padding: titlePadding ??
            EdgeInsets.fromLTRB(24.0, 24.0, 24.0, content == null ? 20.0 : 0.0),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.title,
          child: Semantics(child: title, namesRoute: true),
        ),
      ));
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
          label = semanticLabel;
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          label = semanticLabel ??
              MaterialLocalizations.of(context)?.alertDialogLabel;
      }
    }

    if (content != null) {
      children.add(Flexible(
        child: Padding(
          padding: contentPadding,
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.subhead,
            child: content,
          ),
        ),
      ));
    }

    if (actions != null) {
      children.add(ButtonTheme.bar(
        child: ButtonBar(
          children: actions,
        ),
      ));
    }

    Widget dialogChild = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    if (label != null)
      dialogChild =
          Semantics(namesRoute: true, label: label, child: dialogChild);

    return dialogChild;
  }
}
