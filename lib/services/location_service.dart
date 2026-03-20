import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    final permission = await _ensurePermission();
    if (!permission) {
      return null;
    }

    const settings = LocationSettings(accuracy: LocationAccuracy.high);
    return Geolocator.getCurrentPosition(locationSettings: settings);
  }

  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return false;
    }

    return true;
  }
}
