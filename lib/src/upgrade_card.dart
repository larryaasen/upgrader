/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';

import 'alert_style_widget.dart';
import 'upgrade_messages.dart';
import 'upgrader.dart';

/// A widget to display the upgrade card.
class UpgradeCard extends StatefulWidget {
  /// Creates a new [UpgradeCard].
  UpgradeCard({
    super.key,
    Upgrader? upgrader,
    this.margin,
    this.maxLines = 15,
    this.onIgnore,
    this.onLater,
    this.onUpdate,
    this.overflow = TextOverflow.ellipsis,
    this.showIgnore = true,
    this.showLater = true,
    this.showReleaseNotes = true,
  }) : upgrader = upgrader ?? Upgrader.sharedInstance;

  /// The upgraders used to configure the upgrade dialog.
  final Upgrader upgrader;

  /// The empty space that surrounds the card.
  ///
  /// The default margin is [Card.margin].
  final EdgeInsetsGeometry? margin;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// Called when the ignore button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onIgnore;

  /// Called when the later button is tapped or otherwise activated.
  final VoidCallback? onLater;

  /// Called when the update button is tapped or otherwise activated.
  /// Return false when the default behavior should not execute.
  final BoolCallback? onUpdate;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// Hide or show Ignore button on dialog (default: true)
  final bool showIgnore;

  /// Hide or show Later button on dialog (default: true)
  final bool showLater;

  /// Hide or show release notes (default: true)
  final bool showReleaseNotes;

  @override
  UpgradeCardBaseState createState() => UpgradeCardBaseState();
}

class UpgradeCardBaseState extends State<UpgradeCard> {
  @override
  void initState() {
    super.initState();
    widget.upgrader.initialize();
  }

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context) {
    if (widget.upgrader.debugLogging) {
      print('upgrader: build UpgradeCard');
    }

    return StreamBuilder(
        initialData: widget.upgrader.evaluationReady,
        stream: widget.upgrader.evaluationStream,
        builder: (BuildContext context,
            AsyncSnapshot<UpgraderEvaluateNeed> snapshot) {
          if ((snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active) &&
              snapshot.data != null &&
              snapshot.data!) {
            if (widget.upgrader.shouldDisplayUpgrade()) {
              return buildUpgradeCard(context);
            } else {
              if (widget.upgrader.debugLogging) {
                print('upgrader: UpgradeCard will not display');
              }
            }
          }
          return const SizedBox.shrink();
        });
  }

  /// Build the UpgradeCard Widget.
  Widget buildUpgradeCard(BuildContext context) {
    final appMessages = widget.upgrader.determineMessages(context);
    final title = appMessages.message(UpgraderMessage.title);
    final message = widget.upgrader.body(appMessages);
    final releaseNotes = widget.upgrader.releaseNotes;

    final isBlocked = widget.upgrader.blocked();
    final showIgnore = isBlocked ? false : widget.showIgnore;
    final showLater = isBlocked ? false : widget.showLater;

    if (widget.upgrader.debugLogging) {
      print('upgrader: UpgradeCard: will display');
      print('upgrader: UpgradeCard: showDialog title: $title');
      print('upgrader: UpgradeCard: showDialog message: $message');
      print(
          'upgrader: UpgradeCard: shouldDisplayReleaseNotes: $shouldDisplayReleaseNotes');

      print('upgrader: UpgradeCard: showDialog releaseNotes: $releaseNotes');
    }

    Widget? notes;
    if (shouldDisplayReleaseNotes && releaseNotes != null) {
      notes = Padding(
          padding: const EdgeInsets.only(top: 15.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(appMessages.message(UpgraderMessage.releaseNotes) ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                releaseNotes,
                maxLines: widget.maxLines,
                overflow: widget.overflow,
              ),
            ],
          ));
    }

    return Card(
        // color: Colors.white,
        margin: widget.margin,
        child: AlertStyleWidget(
            title: Text(title ?? ''),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message),
                Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: Text(
                        appMessages.message(UpgraderMessage.prompt) ?? '')),
                if (notes != null) notes,
              ],
            ),
            actions: <Widget>[
              if (showIgnore)
                TextButton(
                    child: Text(appMessages
                            .message(UpgraderMessage.buttonTitleIgnore) ??
                        ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      widget.upgrader.saveLastAlerted();

                      onUserIgnored();
                      forceUpdateState();
                    }),
              if (showLater)
                TextButton(
                    child: Text(
                        appMessages.message(UpgraderMessage.buttonTitleLater) ??
                            ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      widget.upgrader.saveLastAlerted();

                      onUserLater();
                      forceUpdateState();
                    }),
              TextButton(
                  child: Text(
                      appMessages.message(UpgraderMessage.buttonTitleUpdate) ??
                          ''),
                  onPressed: () {
                    // Save the date/time as the last time alerted.
                    widget.upgrader.saveLastAlerted();

                    onUserUpdated();
                  }),
            ]));
  }

  void forceUpdateState() => setState(() {});

  bool get shouldDisplayReleaseNotes =>
      widget.showReleaseNotes &&
      (widget.upgrader.releaseNotes?.isNotEmpty ?? false);

  void onUserIgnored() {
    if (widget.upgrader.debugLogging) {
      print('upgrader: button tapped: ignore');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onIgnore?.call() ?? true;

    if (doProcess) {
      widget.upgrader.saveIgnored();
    }

    forceUpdateState();
  }

  void onUserLater() {
    if (widget.upgrader.debugLogging) {
      print('upgrader: button tapped: later');
    }

    // If this callback has been provided, call it.
    widget.onLater?.call();

    forceUpdateState();
  }

  void onUserUpdated() {
    if (widget.upgrader.debugLogging) {
      print('upgrader: button tapped: update now');
    }

    // If this callback has been provided, call it.
    final doProcess = widget.onUpdate?.call() ?? true;

    if (doProcess) {
      widget.upgrader.sendUserToAppStore();
    }

    forceUpdateState();
  }
}
