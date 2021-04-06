import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/utils/json_converters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:vector_math/vector_math_64.dart' as vect;

// Type definitions to enforce a consistent use of the API
typedef ARHitResultHandler = void Function(List<ARHitTestResult> hits);

/// Manages the session configuration, parameters and events of an [ARView]
class ARSessionManager {
  /// Platform channel used for communication from and to [ARSessionManager]
  MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  /// Context of the [ARView] widget that this manager is attributed to
  final BuildContext buildContext;

  /// Determines the types of planes ARCore and ARKit should show
  final PlaneDetectionConfig planeDetectionConfig;

  /// Receives hit results from user taps with tracked planes or feature points
  ARHitResultHandler onPlaneOrPointTap;

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
        case 'onPlaneOrPointTap':
          if (onPlaneOrPointTap != null) {
            final rawHitTestResults = call.arguments as List<dynamic>;
            final serializedHitTestResults = rawHitTestResults
                .map(
                    (hitTestResult) => Map<String, dynamic>.from(hitTestResult))
                .toList();
            final hitTestResults = serializedHitTestResults.map((e) {
              return ARHitTestResult.fromJson(e);
            }).toList();
            onPlaneOrPointTap(hitTestResults);
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

  /// Function to initialize the platform-specific AR view. Can be used to initially set or update session settings.
  /// [customPlaneTexturePath] refers to flutter assets from the app that is calling this function, NOT to assets within this plugin. Make sure
  /// the assets are correctly registered in the pubspec.yaml of the parent app (e.g. the ./example app in this plugin's repo)
  onInitialize({
    bool showFeaturePoints = false,
    bool showPlanes = true,
    String customPlaneTexturePath,
    bool showWorldOrigin = false,
    bool handleTaps = true,
  }) {
    _channel.invokeMethod<void>('init', {
      'showFeaturePoints': showFeaturePoints,
      'planeDetectionConfig': planeDetectionConfig.index,
      'showPlanes': showPlanes,
      'customPlaneTexturePath': customPlaneTexturePath,
      'showWorldOrigin': showWorldOrigin,
      'handleTaps': handleTaps,
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

  /// Returns the camera pose with respect to the world coordinate system of the [ARView]
  Future<Matrix4> getCameraPose() async {
    try {
      final serializedCameraPose =
          await _channel.invokeMethod<List<dynamic>>('getCameraPose', {});
      return MatrixConverter().fromJson(serializedCameraPose);
    } catch (e) {
      print('Error caught: ' + e);
      return null;
    }
  }

  dynamic getLookRotationAsVector(
      vect.Vector3 cameraPose, vect.Vector3 positionObject,
      {bool asQuaternion = false}) {
    vect.Vector3 direction = cameraPose - positionObject;
    vect.Quaternion lookRotation =
        getLookRotation(direction, vect.Vector3(0, 1, 0));
    if (asQuaternion) return lookRotation;
    return vect.Vector4(
        lookRotation[0], lookRotation[1], lookRotation[2], lookRotation[3]);
  }

  vect.Quaternion getLookRotation(
      vect.Vector3 forwardInWorld, vect.Vector3 desiredUpInWorld) {
    // Find the rotation between the world forward and the forward to look at.
    vect.Quaternion rotateForwardToDesiredForward =
        vect.Quaternion.fromTwoVectors(vect.Vector3(0, 0, -1), forwardInWorld);
    // Recompute upwards so that it's perpendicular to the direction
    vect.Vector3 rightInWorld = forwardInWorld.cross(desiredUpInWorld);
    desiredUpInWorld = rightInWorld.cross(forwardInWorld);
    // Find the rotation between the "up" of the rotated object, and the desired up
    vect.Vector3 newUp =
        rotateForwardToDesiredForward.rotate(vect.Vector3(0, 1, 0));

    vect.Quaternion rotateNewUpToUpwards =
        vect.Quaternion.fromTwoVectors(newUp, desiredUpInWorld);

    return rotateNewUpToUpwards * rotateForwardToDesiredForward;
  }
}
