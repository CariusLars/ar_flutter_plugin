import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';

class ARSessionManager {
  /// Platform channel used for communication from / to [ARSessionManager]
  MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  /// Context of the [ARView] widget that this manager is attributed to
  final BuildContext buildContext;

  /// Determines the types of planes ARCore and ARKit should show
  final PlaneDetectionConfig planeDetectionConfig;

  /// Manages the session configuration, parameters and events of an [ARView]
  ARSessionManager(int id, this.buildContext, this.planeDetectionConfig,
      {this.debug = false}) {
    _channel = MethodChannel('arsession_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
    if (debug) {
      print("ARSessionManager initialized");
    }
  }

  Future<void> _platformCallHandler(MethodCall call) {
    if (debug) {
      print('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            onError(call.arguments[0]);
            print(call.arguments);
          }
          break;
        default:
          if (debug) {
            print('Unimplemented method ${call.method} ');
          }
      }
    } catch (e) {
      print('Error caught: ' + e);
    }
    return Future.value();
  }

  onInitialize(
      {bool showFeaturePoints = false,
      bool showPlanes = true,
      bool showWorldOrigin = false}) {
    _channel.invokeMethod<void>('init', {
      'showFeaturePoints': showFeaturePoints,
      'planeDetectionConfig': planeDetectionConfig.index,
      'showPlanes': showPlanes,
      'showWorldOrigin': showWorldOrigin,
    });
  }

  /// Displays the [errorMessage] in a snackbar of the parent widget
  onError(String errorMessage) {
    ScaffoldMessenger.of(buildContext).showSnackBar(SnackBar(
        content: Text(errorMessage),
        action: SnackBarAction(
            label: 'HIDE',
            onPressed:
                ScaffoldMessenger.of(buildContext).hideCurrentSnackBar)));
  }
}
