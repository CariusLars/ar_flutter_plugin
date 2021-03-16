import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

class CloudAnchorWidget extends StatefulWidget {
  CloudAnchorWidget({Key key}) : super(key: key);
  @override
  _CloudAnchorWidgetState createState() => _CloudAnchorWidgetState();
}

class _CloudAnchorWidgetState extends State<CloudAnchorWidget> {
  ARSessionManager arSessionManager;
  ARObjectManager arObjectManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Anchors'),
        ),
        body: Container(
            child: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
        ])));
  }

  void onARViewCreated(ARSessionManager arSessionManager,
      ARObjectManager arObjectManager, ARAnchorManager arAnchorManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: false,
        );
    this.arObjectManager.onInitialize();
  }
}
