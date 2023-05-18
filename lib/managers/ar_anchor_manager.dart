import 'dart:developer' as developer;

import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

// Type definitions to enforce a consistent use of the API
typedef AnchorUploadedHandler = void Function(ARAnchor arAnchor);
typedef AnchorDownloadedHandler = ARAnchor Function(
    Map<String, dynamic> serializedAnchor);

/// Handles all anchor-related functionality of an [ARView], including configuration and usage of collaborative sessions
class ARAnchorManager {
  /// Platform channel used for communication from and to [ARAnchorManager]
  late MethodChannel _channel;

  /// Debugging status flag. If true, all platform calls are printed. Defaults to false.
  final bool debug;

  /// Reference to all anchors that are being uploaded to the google cloud anchor API
  List<ARAnchor> pendingAnchors = [];

  /// Callback that is triggered once an anchor has successfully been uploaded to the google cloud anchor API
  AnchorUploadedHandler? onAnchorUploaded;

  /// Callback that is triggered once an anchor has successfully been downloaded from the google cloud anchor API and resolved within the current scene
  AnchorDownloadedHandler? onAnchorDownloaded;

  ARAnchorManager(int id, {this.debug = false}) {
    _channel = MethodChannel('aranchors_$id');
    _channel.setMethodCallHandler(_platformCallHandler);

    developer.log("$runtimeType initialized");
  }

  /// Activates collaborative AR mode (using Google Cloud Anchors)
  initGoogleCloudAnchorMode() async {
    _channel.invokeMethod<bool>('initGoogleCloudAnchorMode', {});
  }

  Future<dynamic> _platformCallHandler(MethodCall call) async {
    developer.log('_platformCallHandler call ${call.method} ${call.arguments}');

    try {
      switch (call.method) {
        case 'onError':
          developer.log(call.arguments);
          break;
        case 'onCloudAnchorUploaded':
          final name = call.arguments["name"];
          final cloudanchorid = call.arguments["cloudanchorid"];

          developer.log(
            "UPLOADED ANCHOR WITH ID: " + cloudanchorid + ", NAME: " + name,
          );

          final currentAnchor =
              pendingAnchors.where((element) => element.name == name).first;
          // Update anchor with cloud anchor ID
          (currentAnchor as ARPlaneAnchor).cloudanchorid = cloudanchorid;
          // Remove anchor from list of pending anchors
          pendingAnchors.remove(currentAnchor);
          // Notify callback
          if (onAnchorUploaded != null) {
            onAnchorUploaded!(currentAnchor);
          }
          break;
        case "onAnchorDownloadSuccess":
          final serializedAnchor = call.arguments;
          if (onAnchorDownloaded != null) {
            ARAnchor anchor = onAnchorDownloaded!(
                Map<String, dynamic>.from(serializedAnchor));
            return anchor.name;
          } else {
            return serializedAnchor["name"];
          }
        default:
          developer.log('Unknown method ${call.method}');
      }
    } catch (e) {
      developer.log(
        'Exception in platform call handler: $e',
        name: 'ar_anchor_manager',
      );
    }

    return Future.value();
  }

  /// Add given anchor to the underlying AR scene
  Future<bool?> addAnchor(ARAnchor anchor) async {
    try {
      return await _channel.invokeMethod<bool>('addAnchor', anchor.toJson());
    } on PlatformException catch (e) {
      return false;
    }
  }

  /// Remove given anchor and all its children from the AR Scene
  removeAnchor(ARAnchor anchor) {
    _channel.invokeMethod<String>('removeAnchor', {'name': anchor.name});
  }

  /// Upload given anchor from the underlying AR scene to the Google Cloud Anchor API
  Future<bool?> uploadAnchor(ARAnchor anchor) async {
    try {
      final response =
          await _channel.invokeMethod<bool>('uploadAnchor', anchor.toJson());
      pendingAnchors.add(anchor);
      return response;
    } on PlatformException catch (e) {
      return false;
    }
  }

  /// Try to download anchor with the given ID from the Google Cloud Anchor API and add it to the scene
  Future<bool?> downloadAnchor(String cloudanchorid) async {
    developer.log("TRYING TO DOWNLOAD ANCHOR WITH ID " + cloudanchorid);

    _channel
        .invokeMethod<bool>('downloadAnchor', {"cloudanchorid": cloudanchorid});
  }
}
