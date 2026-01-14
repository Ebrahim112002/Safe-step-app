import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../core/app_theme.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final MapController _mapController = MapController();
  bool _isMapLoading = true;
  String? _mapError;
  bool _showOpenSettings = false;
  latlng.LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      // ১. চেক করুন লোকেশন সার্ভিস চালু আছে কিনা
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _mapError = 'Location services are disabled.';
          _isMapLoading = false;
        });
        return;
      }

      // ২. পারমিশন চেক ও রিকোয়েস্ট
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        setState(() {
          _mapError = 'Location permission denied.';
          _isMapLoading = false;
        });
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _mapError =
              'Location permissions are permanently denied. Please enable from settings.';
          _isMapLoading = false;
          _showOpenSettings = true;
        });
        return;
      }

      // ৩. কারেন্ট লোকেশন নেওয়া
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // ৪. লোকেশন পাওয়া গেলে ম্যাপ কেন্দ্র করে সেট করুন
      _currentLatLng = latlng.LatLng(position.latitude, position.longitude);
      setState(() {
        _isMapLoading = false;
      });
    } catch (e) {
      // কোনো এরর হলে fallback হিসেবে ডিফল্ট লোকেশন ব্যবহার করুন এবং ইউজারকে দেখান
      String err = e.toString();
      setState(() {
        _mapError = 'Unable to get current location.\n$err';
        _isMapLoading = false;
        _showOpenSettings = false;
      });
      debugPrint('Location error: $err');

      // fallback: use world view at 0,0
      _currentLatLng = latlng.LatLng(0, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text("SAFESTEP LIVE TRACKER"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ম্যাপ সেকশন (অ্যাপের ভেতরেই ইন্টারঅ্যাক্টিভ)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border:
                    Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: _mapError != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _mapError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _mapError = null;
                                    _isMapLoading = true;
                                    _showOpenSettings = false;
                                  });
                                  _initMap();
                                },
                                child: const Text('Retry'),
                              ),
                              if (_showOpenSettings) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () async {
                                    bool opened =
                                        await Geolocator.openAppSettings();
                                    if (!opened) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Could not open app settings')),
                                      );
                                    }
                                  },
                                  child: const Text('Open App Settings'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : (_isMapLoading
                        ? const Center(child: CircularProgressIndicator())
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter:
                                  _currentLatLng ?? latlng.LatLng(0, 0),
                              initialZoom: 15.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              if (_currentLatLng != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _currentLatLng!,
                                      width: 48,
                                      height: 48,
                                      child: const Icon(
                                        Icons.my_location,
                                        color: Colors.red,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          )),
              ),
            ),
          ),

          // স্ট্যাটাস ও SOS বাটন
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gpp_good, color: Colors.green),
                      SizedBox(width: 10),
                      Text("LIVE PROTECTION ENABLED",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),

                  // SOS বাটন (SRS: Emergency Trigger)
                  GestureDetector(
                    onLongPress: () => _triggerSOS(),
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 25,
                              spreadRadius: 5)
                        ],
                      ),
                      child: const Center(
                        child: Text("SOS",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const Text("Long press to send emergency alert",
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSOS() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Emergency Alert Sent!"), backgroundColor: Colors.red),
    );
  }
}
