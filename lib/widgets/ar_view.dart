import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class ARView extends StatelessWidget {
  ARView({Key key}) : super(key: key);

  @override
  build(BuildContext context) {
    return Column(children: [
      Text(Theme.of(context).platform.toString()),
      Expanded(
          child: PlatformARView(Theme.of(context).platform)
              .build(context: context)),
    ]);
  }
}
