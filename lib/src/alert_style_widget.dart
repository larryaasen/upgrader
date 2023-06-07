/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';

class AlertStyleWidget extends StatelessWidget {
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
  /// Typically this is a list of [TextButton] widgets.
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
  final Widget? title;

  const AlertStyleWidget({
    Key? key,
    required this.content,
    required this.actions,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final children = <Widget>[];
    const semanticLabel = 'semanticLabel';
    const EdgeInsetsGeometry? titlePadding = null;
    const EdgeInsetsGeometry contentPadding =
        EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0);

    var label = semanticLabel;

    if (title != null) {
      children.add(Padding(
        padding:
            titlePadding ?? const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleLarge!,
          child: Semantics(namesRoute: true, child: title),
        ),
      ));
    } else {
      label = 'Alert';
    }

    children.add(Flexible(
      child: Padding(
        padding: contentPadding,
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.titleMedium!,
          child: content,
        ),
      ),
    ));

    children.add(
      ButtonBar(
        children: actions,
      ),
    );

    Widget dialogChild = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    dialogChild = Semantics(namesRoute: true, label: label, child: dialogChild);

    return dialogChild;
  }
}
