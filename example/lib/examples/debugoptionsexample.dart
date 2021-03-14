import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

class DebugOptionsWidget extends StatefulWidget {
  DebugOptionsWidget({Key key}) : super(key: key);
  @override
  _DebugOptionsWidgetState createState() => _DebugOptionsWidgetState();
}

class _DebugOptionsWidgetState extends State<DebugOptionsWidget> {
  ARSessionManager arSessionManager;
  ARObjectManager arObjectManager;
  bool _showFeaturePoints = false;
  bool _showPlanes = false;
  bool _showWorldOrigin = false;
  String _planeTexturePath = "Images/triangle.png";
  bool _handleTaps = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Debug Options'),
        ),
        body: Container(
            child: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
            showPlatformType: true,
          ),
          Align(
            alignment: FractionalOffset.bottomRight,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              color: Color(0xFFFFFFF).withOpacity(0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Feature Points'),
                    value: _showFeaturePoints,
                    onChanged: (bool value) {
                      setState(() {
                        _showFeaturePoints = value;
                        updateSessionSettings();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Planes'),
                    value: _showPlanes,
                    onChanged: (bool value) {
                      setState(() {
                        _showPlanes = value;
                        updateSessionSettings();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('World Origin'),
                    value: _showWorldOrigin,
                    onChanged: (bool value) {
                      setState(() {
                        _showWorldOrigin = value;
                        updateSessionSettings();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ])));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager, ARObjectManager arObjectManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager.onInitialize(
          showFeaturePoints: _showFeaturePoints,
          showPlanes: _showPlanes,
          customPlaneTexturePath: _planeTexturePath,
          showWorldOrigin: _showWorldOrigin,
          handleTaps: _handleTaps,
        );
    this.arObjectManager.onInitialize();
  }

  void updateSessionSettings() {
    this.arSessionManager.onInitialize(
          showFeaturePoints: _showFeaturePoints,
          showPlanes: _showPlanes,
          customPlaneTexturePath: _planeTexturePath,
          showWorldOrigin: _showWorldOrigin,
        );
  }
}
