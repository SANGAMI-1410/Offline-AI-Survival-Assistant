import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GpsService {
  GpsService._privateConstructor();
  static final GpsService instance = GpsService._privateConstructor();

  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _trail = [];
  Position? _currentPosition;

  List<LatLng> get trail => _trail;
  Position? get currentPosition => _currentPosition;

  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> startTracking(Function(LatLng) onNewPosition) async {
    bool hasPermission = await requestPermissions();
    if (!hasPermission) return;

    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
      intervalDuration: Duration(seconds: 5),
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      final newLatLng = LatLng(position.latitude, position.longitude);
      _trail.add(newLatLng);
      onNewPosition(newLatLng);
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}
