import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';

class CloudAnchorWidget extends StatelessWidget {
  CloudAnchorWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Anchors'),
        ),
        body: Container(child: ARView()));
  }
}
