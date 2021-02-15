import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Factory method for creating a platform-dependent AR view
abstract class PlatformARView {
  factory PlatformARView(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.android:
        return AndroidARView();
      case TargetPlatform.iOS:
        return IosARView();
      default:
        return null;
    }
  }

  Widget build({@required BuildContext context});

  void onPlatformViewCreated(int id);
}

/// Android-specific implementation of [PlatformARView]
/// Uses Hybrid Composition to increase peformance on Android 9 and below (https://flutter.dev/docs/development/platform-integration/platform-views)
class AndroidARView implements PlatformARView {
  @override
  void onPlatformViewCreated(int id) {
    print("Android platform view created!");
  }

  @override
  Widget build({@required BuildContext context}) {
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

/// iOS-specific implementation of [PlatformARView]
class IosARView implements PlatformARView {
  @override
  void onPlatformViewCreated(int id) {
    print("iOS platform view created!");
  }

  @override
  Widget build({@required BuildContext context}) {
    // This is used in the platform side to register the view.
    final String viewType = 'ar_flutter_plugin';
    // Pass parameters to the platform side.
    final Map<String, dynamic> creationParams = <String, dynamic>{};

    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

/// If camera permission is granted, [ARView] creates a platform-dependent view from the factory method [PlatformARView].
/// If camera permission is not given, the user is prompted to grant it. To modify the UI of the prompts, the following named parameters can be used:
/// [permissionPromptDescription], [permissionPromptButtonText] and [permissionPromptParentalRestriction].
class ARView extends StatefulWidget {
  final String permissionPromptDescription;
  final String permissionPromptButtonText;
  final String permissionPromptParentalRestriction;
  ARView(
      {Key key,
      this.permissionPromptDescription =
          "Camera permission must be given to the app for AR functions to work",
      this.permissionPromptButtonText = "Grant Permission",
      this.permissionPromptParentalRestriction =
          "Camera permission is restriced by the OS, please check parental control settings"})
      : super(key: key);
  @override
  _ARViewState createState() => _ARViewState(
      permissionPromptDescription: this.permissionPromptDescription,
      permissionPromptButtonText: this.permissionPromptButtonText,
      permissionPromptParentalRestriction:
          this.permissionPromptParentalRestriction);
}

class _ARViewState extends State<ARView> {
  PermissionStatus _cameraPermission = PermissionStatus.undetermined;
  String permissionPromptDescription;
  String permissionPromptButtonText;
  String permissionPromptParentalRestriction;

  _ARViewState(
      {@required this.permissionPromptDescription,
      @required this.permissionPromptButtonText,
      @required this.permissionPromptParentalRestriction});

  @override
  void initState() {
    super.initState();
    initCameraPermission();
  }

  initCameraPermission() async {
    requestCameraPermission();
  }

  requestCameraPermission() async {
    final cameraPermission = await Permission.camera.request();
    setState(() {
      _cameraPermission = cameraPermission;
    });
  }

  requestCameraPermissionFromSettings() async {
    final cameraPermission = await Permission.camera.request();
    if (cameraPermission == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
    setState(() {
      _cameraPermission = cameraPermission;
    });
  }

  @override
  build(BuildContext context) {
    switch (_cameraPermission) {
      case (PermissionStatus
          .limited): //iOS-specific: permissions granted for this specific application
      case (PermissionStatus.granted):
        {
          return Column(children: [
            Text(Theme.of(context).platform.toString()),
            Expanded(
                child: PlatformARView(Theme.of(context).platform)
                    .build(context: context)),
          ]);
        }
      case (PermissionStatus.denied):
        {
          return Center(
              child: Column(
            children: [
              Text(permissionPromptDescription),
              ElevatedButton(
                  child: Text(permissionPromptButtonText),
                  onPressed: () async => {await requestCameraPermission()})
            ],
          ));
        }
      case (PermissionStatus
          .permanentlyDenied): //Android-specific: User needs to open Settings to give permissions
        {
          return Center(
              child: Column(
            children: [
              Text(permissionPromptDescription),
              ElevatedButton(
                  child: Text(permissionPromptButtonText),
                  onPressed: () async =>
                      {await requestCameraPermissionFromSettings()})
            ],
          ));
        }
      case (PermissionStatus.restricted):
        {
          //iOS only
          return Center(child: Text(permissionPromptParentalRestriction));
        }
      case (PermissionStatus.undetermined):
        {
          return Text(permissionPromptDescription);
        }
      default:
        return Text('something went wrong');
    }
  }
}
