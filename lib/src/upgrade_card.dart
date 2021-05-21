/*
 * Copyright (c) 2021 Larry Aasen. All rights reserved.
 */

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:upgrader/upgrader.dart';

/// A widget to display the upgrade card.
class UpgradeCard extends UpgradeBase {
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
    bool debugAlwaysUpgrade,
    bool debugDisplayOnce,
    bool debugLogging,
    Duration durationToAlertAgain,
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
          debugDisplayAlways: debugAlwaysUpgrade,
          debugDisplayOnce: debugDisplayOnce,
          debugLogging: debugLogging,
          durationToAlertAgain: durationToAlertAgain,
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
  Widget build(BuildContext context, UpgradeBaseState state) {
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
                  child: AlertStyleWidget(
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
                          TextButton(
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
                          TextButton(
                              child: Text(Upgrader()
                                  .messages
                                  .message(UpgraderMessage.buttonTitleLater)),
                              onPressed: () {
                                // Save the date/time as the last time alerted.
                                Upgrader().saveLastAlerted();

                                Upgrader().onUserLater(context, false);
                                state.forceUpdateState();
                              }),
                        TextButton(
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
