import 'dart:typed_data';

import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

// Type definitions to enforce a consistent use of the API
typedef NodeTapResultHandler = void Function(List<String> nodes);
typedef NodePanStartHandler = void Function(String node);
typedef NodePanChangeHandler = void Function(String node);
typedef NodePanEndHandler = void Function(
    String node, Vector3 newPosition, Quaternion newRotation, Vector3 newScale);
typedef NodeRotationStartHandler = void Function(String node);
typedef NodeRotationChangeHandler = void Function(String node);
typedef NodeRotationEndHandler = void Function(
    String node, Vector3 newPosition, Quaternion newRotation, Vector3 newScale);

/// Manages the all node-related actions of an [ARView]
class ARObjectManager {
  /// Platform channel used for communication from and to [ARObjectManager]
  late MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  /// Callback function that is invoked when the platform detects a tap on a node
  NodeTapResultHandler? onNodeTap;
  NodePanStartHandler? onPanStart;
  NodePanChangeHandler? onPanChange;
  NodePanEndHandler? onPanEnd;
  NodeRotationStartHandler? onRotationStart;
  NodeRotationChangeHandler? onRotationChange;
  NodeRotationEndHandler? onRotationEnd;

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
        case 'onNodeTap':
          if (onNodeTap != null) {
            final tappedNodes = call.arguments as List<dynamic>;
            onNodeTap!(tappedNodes
                .map((tappedNode) => tappedNode.toString())
                .toList());
          }
          break;
        case 'onPanStart':
          print("panStarted");
          if (onPanStart != null) {
            final tappedNode = call.arguments as String;
            // Notify callback
            onPanStart!(tappedNode);
          }
          break;
        case 'onPanChange':
          print("panChanged");
          if (onPanChange != null) {
            final tappedNode = call.arguments as String;
            // Notify callback
            onPanChange!(tappedNode);
          }
          break;
        case 'onPanEnd':
          print("panEnded");
          if (onPanEnd != null) {
            final tappedNodeName = call.arguments["name"] as String;
            final tappedNodePosition =
                call.arguments["position"] as List<dynamic>;
            final tappedNodeRotation =
                call.arguments["rotation"] as List<dynamic>;
            final tappedNodeScale = call.arguments["scale"] as List<dynamic>;

            final positionVector = Vector3(tappedNodePosition[0],
                tappedNodePosition[1], tappedNodePosition[2]);
            final rotationMatix = Quaternion(
                    tappedNodeRotation[0],
                    tappedNodeRotation[1],
                    tappedNodeRotation[2],
                    tappedNodeRotation[3])
                .normalized();
            final scaleVector = Vector3(
                tappedNodeScale[0], tappedNodeScale[1], tappedNodeScale[2]);

            // Notify callback
            onPanEnd!(
                tappedNodeName, positionVector, rotationMatix, scaleVector);
          }
          break;
        case 'onRotationStart':
          print("rotationStarted");
          if (onRotationStart != null) {
            final tappedNode = call.arguments as String;
            onRotationStart!(tappedNode);
          }
          break;
        case 'onRotationChange':
          print("rotationChanged");
          if (onRotationChange != null) {
            final tappedNode = call.arguments as String;
            onRotationChange!(tappedNode);
          }
          break;
        case 'onRotationEnd':
          print("rotationEnded");
          if (onRotationEnd != null) {
            final tappedNodeName = call.arguments["name"] as String;
            final tappedNodePosition =
                call.arguments["position"] as List<dynamic>;
            final tappedNodeRotation =
                call.arguments["rotation"] as List<dynamic>;
            final tappedNodeScale = call.arguments["scale"] as List<dynamic>;

            final positionVector = Vector3(tappedNodePosition[0],
                tappedNodePosition[1], tappedNodePosition[2]);
            final rotationMatix = Quaternion(
                    tappedNodeRotation[0],
                    tappedNodeRotation[1],
                    tappedNodeRotation[2],
                    tappedNodeRotation[3])
                //.normalized();
            final scaleVector = Vector3(
                tappedNodeScale[0], tappedNodeScale[1], tappedNodeScale[2]);

            // Notify callback
            onRotationEnd!(
                tappedNodeName, positionVector, rotationMatix, scaleVector);
          }
          break;
        default:
          if (debug) {
            print('Unimplemented method ${call.method} ');
          }
      }
    } catch (e) {
      print('Error caught: ' + e.toString());
    }
    return Future.value();
  }

  /// Sets up the AR Object Manager
  onInitialize() {
    _channel.invokeMethod<void>('init', {});
  }

  /// Add given node to the given anchor of the underlying AR scene (or to its top-level if no anchor is given) and listen to any changes made to its transformation
  Future<bool?> addNode(ARNode node, {ARPlaneAnchor? planeAnchor}) async {
    try {
      node.transformNotifier.addListener(() {
        _channel.invokeMethod<void>('transformationChanged', {
          'name': node.name,
          'transformation':
              MatrixValueNotifierConverter().toJson(node.transformNotifier)
        });
      });
      if (planeAnchor != null) {
        planeAnchor.childNodes.add(node.name);
        return await _channel.invokeMethod<bool>('addNodeToPlaneAnchor',
            {'node': node.toMap(), 'anchor': planeAnchor.toJson()});
      } else {
        return await _channel.invokeMethod<bool>('addNode', node.toMap());
      }
    } on PlatformException catch (e) {
      return false;
    }
  }

  /// Remove given node from the AR Scene
  removeNode(ARNode node) {
    _channel.invokeMethod<String>('removeNode', {'name': node.name});
  }
}
