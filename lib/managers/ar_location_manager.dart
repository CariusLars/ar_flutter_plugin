import 'dart:async';
import 'dart:developer' as developer;

import 'package:geolocator/geolocator.dart';

/// Can be used to get the current location of the device, update it and handle location permissions
class ARLocationManager {
  late Position currentLocation;
  late StreamSubscription<Position> locationStream;

  /// Returns the last known location of the device or an error, if permissions don't suffice. Automatically queries user permission if possible
  Future<Position?> getLastKnownPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the last known position of the device.
    return await Geolocator.getLastKnownPosition();
  }

  /// Starts high precision location updates to keep track of the device's position. Returns true or an error, if permissions don't suffice. Automatically queries user permission if possible
  Future<bool> startLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    locationStream =
        Geolocator.getPositionStream(desiredAccuracy: LocationAccuracy.high)
            .listen((Position position) {
      developer.log(
        '$runtimeType::getPositionStream: ${position.latitude}, ${position.longitude}',
      );

      currentLocation = position;
    });

    return true;
  }

  /// Stops the high-precision location updates
  void stopLocationUpdates() {
    locationStream.cancel();
  }

  /// Opens the settings of the current application
  void openAppPermissionSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Opens the device settings where location services can be enabled
  void openLocationServicesSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Determines the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions permanently denied');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
