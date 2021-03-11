import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

class LocalAndWebObjectsWidget extends StatefulWidget {
  LocalAndWebObjectsWidget({Key key}) : super(key: key);
  @override
  _LocalAndWebObjectsWidgetState createState() =>
      _LocalAndWebObjectsWidgetState();
}

class _LocalAndWebObjectsWidgetState extends State<LocalAndWebObjectsWidget> {
  ARSessionManager arSessionManager;
  ARObjectManager arObjectManager;
  String localObjectReference;
  String webObjectReference;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Local & Web Objects'),
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
                      onPressed: onLocalObjectAtOriginButtonPressed,
                      child: Text("Add/Remove Local\nobject at Origin")),
                  ElevatedButton(
                      onPressed: onWebObjectAtOriginButtonPressed,
                      child: Text("Add/Remove Web\nObject at Origin")),
                ],
              ))
        ])));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager, ARObjectManager arObjectManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "Images/triangle.png",
          showWorldOrigin: true,
        );
    this.arObjectManager.onInitialize();
  }

  Future<void> onLocalObjectAtOriginButtonPressed() async {
    if (this.localObjectReference != null) {
      this.arObjectManager.removeTopLevelObject(this.localObjectReference);
      this.localObjectReference = null;
    } else {
      var id = await this
          .arObjectManager
          .addObjectAtOrigin("Models/Chicken_01/Chicken_01.gltf", 0.2);
      this.localObjectReference = id;
    }
  }

  Future<void> onWebObjectAtOriginButtonPressed() async {
    if (this.webObjectReference != null) {
      this.arObjectManager.removeTopLevelObject(this.webObjectReference);
      this.webObjectReference = null;
    } else {
      var id = await this.arObjectManager.addWebObjectAtOrigin(
          "https://github.com/KhronosGroup/glTF-Sample-Models/raw/master/2.0/Duck/glTF-Binary/Duck.glb",
          0.2);
      this.webObjectReference = id;
    }
  }
}
