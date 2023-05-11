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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader Example',
      home: Scaffold(
          appBar: AppBar(title: Text('Upgrader Example')),
          body: UpgradeAlert(
            upgrader: CustomUpgrader(),
            child: Center(child: Text('Checking...')),
          )),
    );
  }
}

class CustomUpgrader extends Upgrader {
  CustomUpgrader() : super(dialogStyle: UpgradeDialogStyle.custom);

  @override
  Dialog customAlertDialog(
      String title, String message, String releaseNotes, BuildContext context) {
    return Dialog(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          Text(message),
          Text(releaseNotes),
          Row(
            children: [
              if (showIgnore)
                TextButton(
                    child: Text(
                        messages.message(UpgraderMessage.buttonTitleIgnore)),
                    onPressed: () => onUserIgnored(context, true)),
              if (showLater)
                TextButton(
                    child: Text(
                        messages.message(UpgraderMessage.buttonTitleLater)),
                    onPressed: () => onUserLater(context, true)),
              TextButton(
                  child:
                      Text(messages.message(UpgraderMessage.buttonTitleUpdate)),
                  onPressed: () => onUserUpdated(context, !blocked()))
            ],
          )
        ],
      ),
    );
  }
}
