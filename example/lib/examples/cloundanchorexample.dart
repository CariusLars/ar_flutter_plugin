import 'package:flutter/material.dart';

class CloudAnchorWidget extends StatelessWidget {
  CloudAnchorWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Anchors'),
        ),
        body: Container(child: Text('Hello world')));
  }
}
