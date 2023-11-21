/*
 * Copyright (c) 2021-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

/// A widget to display the upgrade card.
class UpgradeCard extends UpgradeBase {
  /// The empty space that surrounds the card.
  ///
  /// The default margin is 4.0 logical pixels on all sides:
  /// `EdgeInsets.all(4.0)`.
  final EdgeInsetsGeometry margin;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// How visual overflow should be handled.
  final TextOverflow? overflow;

  /// Creates a new [UpgradeCard].
  UpgradeCard({
    super.key,
    Upgrader? upgrader,
    this.margin = const EdgeInsets.all(4.0),
    this.maxLines = 15,
    this.overflow = TextOverflow.ellipsis,
  }) : super(upgrader ?? Upgrader.sharedInstance);

  /// Describes the part of the user interface represented by this widget.
  @override
  Widget build(BuildContext context, UpgradeBaseState state) {
    if (upgrader.debugLogging) {
      print('upgrader: build UpgradeCard');
    }

    return StreamBuilder(
        initialData: state.widget.upgrader.evaluationReady,
        stream: state.widget.upgrader.evaluationStream,
        builder: (BuildContext context,
            AsyncSnapshot<UpgraderEvaluateNeed> snapshot) {
          if ((snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active) &&
              snapshot.data != null &&
              snapshot.data!) {
            if (upgrader.shouldDisplayUpgrade()) {
              return buildUpgradeCard(context, state);
            } else {
              if (upgrader.debugLogging) {
                print('upgrader: UpgradeCard will not display');
              }
            }
          }
          return const SizedBox.shrink();
        });
  }

  /// Build the UpgradeCard Widget.
  Widget buildUpgradeCard(BuildContext context, UpgradeBaseState state) {
    final appMessages = upgrader.determineMessages(context);
    final title = appMessages.message(UpgraderMessage.title);
    final message = upgrader.body(appMessages);
    final releaseNotes = upgrader.releaseNotes;
    final shouldDisplayReleaseNotes = upgrader.shouldDisplayReleaseNotes();
    if (upgrader.debugLogging) {
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
                maxLines: maxLines,
                overflow: overflow,
              ),
            ],
          ));
    }

    return Card(
        color: Colors.white,
        margin: margin,
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
              if (upgrader.showIgnore)
                TextButton(
                    child: Text(appMessages
                            .message(UpgraderMessage.buttonTitleIgnore) ??
                        ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      upgrader.saveLastAlerted();

                      upgrader.onUserIgnored(context, false);
                      state.forceUpdateState();
                    }),
              if (upgrader.showLater)
                TextButton(
                    child: Text(
                        appMessages.message(UpgraderMessage.buttonTitleLater) ??
                            ''),
                    onPressed: () {
                      // Save the date/time as the last time alerted.
                      upgrader.saveLastAlerted();

                      upgrader.onUserLater(context, false);
                      state.forceUpdateState();
                    }),
              TextButton(
                  child: Text(
                      appMessages.message(UpgraderMessage.buttonTitleUpdate) ??
                          ''),
                  onPressed: () {
                    // Save the date/time as the last time alerted.
                    upgrader.saveLastAlerted();

                    upgrader.onUserUpdated(context, false);
                    state.forceUpdateState();
                  }),
            ]));
  }
}
