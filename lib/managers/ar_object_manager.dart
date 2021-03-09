import 'package:flutter/services.dart';

/// Manages the session configuration, parameters and events of an [ARView]
class ARObjectManager {
  /// Platform channel used for communication from and to [ARObjectManager]
  MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  ARObjectManager(int id, {this.debug = false}) {
    _channel = MethodChannel('arobjects_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
    if (debug) {
      print("ARObjectManager initialized");
    }
  }

  Future<void> _platformCallHandler(MethodCall call) {
    if (debug) {
      print('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    try {
      switch (call.method) {
        case 'onError':
          print(call.arguments);
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

  onInitialize() {
    _channel.invokeMethod<void>('init', {});
  }

  addObjectAtOrigin(String objectPath, double scale) {
    _channel.invokeMethod<void>(
        'addObjectAtOrigin', {'objectPath': objectPath, 'scale': scale});
  }

  /// Downloads objects at runtime and places them in the scene. PLEASE NOTE: 1) Only works with GLTF objects 2) apps using this call should check internet connectivity in advance
  addWebObjectAtOrigin(String objectURL, double scale) {
    _channel.invokeMethod<void>(
        'addWebObjectAtOrigin', {'objectURL': objectURL, 'scale': scale});
  }
}
