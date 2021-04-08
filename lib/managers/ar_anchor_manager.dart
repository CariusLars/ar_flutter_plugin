import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

// Type definitions to enforce a consistent use of the API
typedef AnchorUploadedHandler = void Function(ARAnchor arAnchor);
typedef AnchorDownloadedHandler = void Function(ARAnchor arAnchor);

/// Manages the session configuration, parameters and events of an [ARView]
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
    if (debug) {
      print("ARAnchorManager initialized");
    }
  }

  initGoogleCloudAnchorMode(
      String clientIdAndroid, String clientIdIos, BuildContext context) async {
    
    String clientID = "";
    if (Theme.of(context).platform == TargetPlatform.android) {
      clientID = clientIdAndroid;
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      clientID = clientIdIos;
    }
    GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: clientID,
      //scopes: [],
    );
    GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();

    GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    _channel.invokeMethod<bool>('initGoogleCloudAnchorMode', {"token" : googleSignInAuthentication?.accessToken});

    //String? accessToken = googleSignInAuthentication?.accessToken;
    //String? idToken = googleSignInAuthentication?.idToken;
  }

  Future<dynamic> _platformCallHandler(MethodCall call) async {
    if (debug) {
      print('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    try {
      switch (call.method) {
        case 'onError':
          print(call.arguments);
          break;
        case 'onCloudAnchorUploaded':
          final name = call.arguments["name"];
          final cloudanchorid = call.arguments["cloudanchorid"];
          print(
              "UPLOADED ANCHOR WITH ID: " + cloudanchorid + ", NAME: " + name);
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
          // Reset name so the following function assigns a new uniquely identifying name
          serializedAnchor["name"] = null;
          final anchor =
              ARAnchor.fromJson(Map<String, dynamic>.from(serializedAnchor));
          if (onAnchorDownloaded != null) {
            onAnchorDownloaded!(anchor);
          }
          return anchor.name;
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

  Future<bool?> downloadAnchor(String cloudanchorid) async {
    print("TRYING TO DOWNLOAD ANCHOR WITH ID " + cloudanchorid);
    _channel
        .invokeMethod<bool>('downloadAnchor', {"cloudanchorid": cloudanchorid});
  }
}
