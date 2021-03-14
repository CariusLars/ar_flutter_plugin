import 'package:ar_flutter_plugin/models/ar_node.dart';
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

  /// Add given node to the underlying AR scene and listen to any changes made to its transformation
  Future<bool> addNode(ARNode node) async {
    try {
      node.transformNotifier.addListener(() {
        _channel.invokeMethod<void>('transformationChanged', {
          'name': node.name,
          'transformation':
              MatrixValueNotifierConverter().toJson(node.transformNotifier)
        });
      });
      return await _channel.invokeMethod<bool>('addNode', node.toMap());
    } on PlatformException catch (e) {
      return false;
    }
  }

  /// Remove given node from the AR Scene
  removeNode(ARNode node) {
    _channel.invokeMethod<String>('removeNode', {'name': node.name});
  }

  /// Downloads objects at runtime and places them in the scene. PLEASE NOTE: 1) Only works with stand-alone GLB files 2) apps using this call should check internet connectivity in advance
  Future<String> addWebObjectAtOrigin(String objectURL, double scale) async {
    try {
      final String id = await _channel.invokeMethod<String>(
          'addWebObjectAtOrigin', {'objectURL': objectURL, 'scale': scale});
      return id;
    } on PlatformException catch (e) {
      return null;
    }
  }
}
