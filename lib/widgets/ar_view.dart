import 'package:flutter/material.dart';

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

class AndroidARView implements PlatformARView {
  @override
  void onPlatformViewCreated(int id) {
    print("Android platform view created!");
  }

  @override
  Widget build({@required BuildContext context}) {
    return AndroidView(
      viewType: 'ar_flutter_plugin',
      onPlatformViewCreated: onPlatformViewCreated,
    );
  }
}

class IosARView implements PlatformARView {
  @override
  void onPlatformViewCreated(int id) {
    print("iOS platform view created!");
  }

  @override
  Widget build({@required BuildContext context}) {
    return Text('Placeholder for IosARView');
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
