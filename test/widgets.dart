import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';

///Widget used for tests
class MyWidgetTest extends StatelessWidget {
  final Upgrader upgrader;
  const MyWidgetTest({Key? key, required this.upgrader}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: UpgradeAlert(
            upgrader: upgrader,
            child: Column(
              children: const <Widget>[Text('Upgrading')],
            )),
      ),
    );
  }
}

class MyWidgetCardTest extends StatelessWidget {
  final Upgrader upgrader;
  const MyWidgetCardTest({Key? key, required this.upgrader}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upgrader test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Upgrader test'),
        ),
        body: Column(
          children: <Widget>[UpgradeCard(upgrader: upgrader)],
        ),
      ),
    );
  }
}
