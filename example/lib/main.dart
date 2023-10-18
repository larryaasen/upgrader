/*
 * Copyright (c) 2019-2023 Larry Aasen. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only call clearSavedSettings() during testing to reset internal values.
  await Upgrader.clearSavedSettings(); // REMOVE this for release builds

  // On Android, the default behavior will be to use the Google Play Store
  // version of the app.
  // On iOS, the default behavior will be to use the App Store version of
  // the app, so update the Bundle Identifier in example/ios/Runner with a
  // valid identifier already in the App Store.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Upgrader Example',
      home: const PageWithAlert(),
    );
  }
}

class PageWithAlert extends StatefulWidget {
  const PageWithAlert({
    super.key,
  });

  @override
  State<PageWithAlert> createState() => _PageWithAlertState();
}

class _PageWithAlertState extends State<PageWithAlert> {
  var upgrader = Upgrader(
    canDismissDialog: true,
    durationUntilAlertAgain: Duration(minutes: 1),
  );

  @override
  void initState() {
    showsDialog();
    super.initState();
  }

  void showsDialog() {
    Future.delayed(Duration(seconds: 3)).then((_) async {
      await showDialog(
        context: context,
        builder: (_) => Center(
          heightFactor: 1,
          widthFactor: 1,
          child: Material(
            child: Container(
              color: Colors.amber,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('HAHA'),
                    ElevatedButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text(
                        'Close this dialog',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: upgrader.popNavigator,
                      child: Text(
                        'Close Upgrade dialog',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void closeDialogByName(String routeName) {
    final state = MyApp.navigatorKey.currentState;

    if (state == null) return;
  }

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: upgrader,
      useSafeArea: false,
      // content: (
      //   appName,
      //   appStoreVersion,
      //   appInstalledVersion,
      //   VoidCallback onUpdate,
      // ) {
      //   return ExampleDialogContent(
      //     appName: appName,
      //     appStoreVersion: appStoreVersion,
      //     appInstalledVersion: appInstalledVersion,
      //     onUpdate: onUpdate,
      //   );
      // },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Upgrader Example'),
        ),
        body: Column(
          children: [
            Center(
              child: Text('Checking...'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExampleDialogContent extends StatelessWidget {
  const ExampleDialogContent({
    super.key,
    required this.appName,
    required this.appStoreVersion,
    required this.appInstalledVersion,
    required this.onUpdate,
  });

  final String appName;
  final String appStoreVersion;
  final String appInstalledVersion;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 1,
      widthFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 120,
          minWidth: 120,
        ),
        child: Card(
          color: Colors.green,
          // elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(appName),
                SizedBox(height: 12),
                Text(appStoreVersion),
                SizedBox(height: 12),
                Text(appInstalledVersion),
                TextButton(onPressed: onUpdate, child: Text('Update')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
