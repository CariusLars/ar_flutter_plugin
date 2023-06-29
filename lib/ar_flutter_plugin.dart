import 'dart:async';

import 'package:flutter/services.dart';

export 'package:ar_flutter_plugin/widgets/ar_view.dart';

class ArFlutterPlugin {
  static const MethodChannel _channel = MethodChannel('ar_flutter_plugin');

  /// Private constructor to prevent accidental instantiation of the Plugin using the implicit default constructor
  ArFlutterPlugin._();

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
