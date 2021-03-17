// The code in this file is adapted from Oleksandr Leuschenko' ARKit Flutter Plugin (https://github.com/olexale/arkit_flutter_plugin)

import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/utils/json_converters.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

/// A result of an intersection found during a hit-test.
class ARHitTestResult {
  ARHitTestResult(
    this.type,
    this.distance,
    this.worldTransform,
  );

  /// The type of the hit-test result.
  final ARHitTestResultType type;

  /// The distance from the camera to the intersection in meters.
  final double distance;

  /// The transformation matrix that defines the intersection’s rotation, translation and scale
  /// relative to the world.
  final Matrix4 worldTransform;

  static ARHitTestResult fromJson(Map<String, dynamic> json) =>
      _$ARHitTestResultFromJson(json);

  Map<String, dynamic> toJson() => _$ARHitTestResultToJson(this);
}

ARHitTestResult _$ARHitTestResultFromJson(Map<String, dynamic> json) {
  return ARHitTestResult(
    const ARHitTestResultTypeConverter().fromJson(json['type'] as int),
    (json['distance'] as num).toDouble(),
    const MatrixConverter().fromJson(json['worldTransform'] as List),
  );
}

Map<String, dynamic> _$ARHitTestResultToJson(ARHitTestResult instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull(
      'type', const ARHitTestResultTypeConverter().toJson(instance.type));
  val['distance'] = instance.distance;
  writeNotNull('worldTransform',
      const MatrixConverter().toJson(instance.worldTransform));
  return val;
}

class ARHitTestResultTypeConverter
    implements JsonConverter<ARHitTestResultType, int> {
  const ARHitTestResultTypeConverter();

  @override
  ARHitTestResultType fromJson(int json) {
    switch (json) {
      case 1:
        return ARHitTestResultType.plane;
      case 2:
        return ARHitTestResultType.point;
      default:
        return ARHitTestResultType.undefined;
    }
  }

  @override
  int toJson(ARHitTestResultType object) {
    switch (object) {
      case ARHitTestResultType.plane:
        return 1;
      case ARHitTestResultType.point:
        return 2;
      default:
        return 0;
    }
  }
}
