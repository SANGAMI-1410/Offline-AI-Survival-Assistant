import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import '../services/gps_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _currentPosition;
  double? _altitude;
  final MapController _mapController = MapController();
  bool _gpsError = false;

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  void _startGps() async {
    try {
      await GpsService.instance.startTracking((LatLng newPosition) {
        if (mounted) {
          setState(() {
            _currentPosition = newPosition;
            _altitude = GpsService.instance.currentPosition?.altitude;
            _gpsError = false;
          });
          try {
            _mapController.move(newPosition, 16.0);
          } catch (_) {}
        }
      });
    } catch (_) {
      if (mounted) setState(() => _gpsError = true);
    }
  }

  @override
  void dispose() {
    GpsService.instance.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPS Trail',
          style: TextStyle(
              color: Color(0xFFf0ede6), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1a2e1a),
        iconTheme: const IconThemeData(color: Color(0xFFf0ede6)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2d4a2d),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${GpsService.instance.trail.length} pts',
                  style: const TextStyle(
                    color: Color(0xFFa8d5a2),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentPosition ?? const LatLng(20.5937, 78.9629),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.forest_ai',
                tileProvider: FMTCStore('mapStore').getTileProvider(
                  settings: FMTCTileProviderSettings(
                    behavior: CacheBehavior.cacheFirst,
                  ),
                ),
                errorTileCallback: (tile, error, stackTrace) {},
              ),
              // Orange trail
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: GpsService.instance.trail,
                    color: const Color(0xFFe8a020),
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              // Blue position dot
              if (_currentPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition!,
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.25),
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border:
                                  Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // GPS error banner
          if (_gpsError)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: const Color(0xFFc0392b),
                padding: const EdgeInsets.all(10),
                child: const Text(
                  '⚠️  Location permission denied. Enable GPS in settings.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Acquiring GPS overlay
          if (_currentPosition == null && !_gpsError)
            Center(
              child: Card(
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF1a2e1a)),
                      SizedBox(height: 16),
                      Text('Acquiring GPS Signal...',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Go outside for better signal',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Coordinates bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: const Color(0xFF1a2e1a).withValues(alpha: 0.92),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _coordItem('LAT',
                      _currentPosition?.latitude.toStringAsFixed(5) ?? '—'),
                  _divider(),
                  _coordItem('LNG',
                      _currentPosition?.longitude.toStringAsFixed(5) ?? '—'),
                  _divider(),
                  _coordItem(
                    'ALT',
                    _altitude != null
                        ? '${_altitude!.toStringAsFixed(1)} m'
                        : '—',
                  ),
                  _divider(),
                  _coordItem('PTS',
                      '${GpsService.instance.trail.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFFa8d5a2),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: Color(0xFFf0ede6),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            )),
      ],
    );
  }

  Widget _divider() => Container(
        height: 30, width: 1, color: const Color(0xFF2d4a2d));
}
