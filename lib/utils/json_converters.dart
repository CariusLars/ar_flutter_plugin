// The code in this file is adapted from Oleksandr Leuschenko' ARKit Flutter Plugin (https://github.com/olexale/arkit_flutter_plugin)
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

class MatrixConverter implements JsonConverter<Matrix4, List<dynamic>> {
  const MatrixConverter();

  @override
  Matrix4 fromJson(List<dynamic> json) {
    return Matrix4.fromList(json.cast<double>());
  }

  @override
  List<dynamic> toJson(Matrix4 matrix) {
    final list = List<double>(16);
    matrix.copyIntoArray(list);
    return list;
  }
}
