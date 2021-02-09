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
}

class AndroidARView implements PlatformARView {
  @override
  Widget build({@required BuildContext context}) {
    return Text('Placeholder for AndroidARView');
  }
}

class IosARView implements PlatformARView {
  @override
  Widget build({@required BuildContext context}) {
    return Text('Placeholder for IosARView');
  }
}
