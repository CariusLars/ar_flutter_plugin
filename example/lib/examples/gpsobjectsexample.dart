import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

class GpsObjectsWidget extends StatefulWidget {
  GpsObjectsWidget({Key key}) : super(key: key);
  @override
  _GpsObjectsWidgetState createState() => _GpsObjectsWidgetState();
}

class _GpsObjectsWidgetState extends State<GpsObjectsWidget> {
  ARSessionManager arSessionManager;
  ARObjectManager arObjectManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('GPS Objects'),
        ),
        body: Container(
            child: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                      onPressed: onPlaceGpsObject,
                      child: Text("Place GPS Object")),
                ]),
          )
        ])));
  }

  void onARViewCreated(ARSessionManager arSessionManager,
      ARObjectManager arObjectManager, ARAnchorManager arAnchorManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: false,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: false,
        );
    this.arObjectManager.onInitialize();
  }

  void onPlaceGpsObject() async {
    final Matrix4 cameraPose = await arSessionManager.getCameraPose();
    if (cameraPose != null) {
      print("THE CAMERA POSE IS:");
      print(cameraPose);
      // TODO: Add code here
    } else {
      print("Error getting the camera pose");
    }
  }
}
