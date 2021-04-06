import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart' as vect;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:proj4dart/proj4dart.dart';

class ARLocationManager {
  Point convertGPStoUTM(LatLng coord) {
    var pointSrc = Point(x: coord.longitude, y: coord.latitude);

    var projSrc =
        Projection.parse('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs');

    var projDst = Projection.parse('+proj=utm +zone=31');

    var result = projSrc.transform(projDst, pointSrc);

    print(result);

    return result;
  }

  vect.Vector3 transformPointToAR(LatLng position, LatLng point) {
    var objPoint = convertGPStoUTM(point);

    var devicePoint = convertGPStoUTM(position);

// latitude(north,south) maps to the z axis in AR

// longitude(east, west) maps to the x axis in AR

    var objFinalPosZ = objPoint.y - devicePoint.y;

    var objFinalPosX = objPoint.x - devicePoint.x;

//flip the z, as negative z(is in front of us which is north, pos z is behind(south).

    return vect.Vector3(objFinalPosX, 0, -objFinalPosZ);
  }
}
