import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import '../core/app_theme.dart';


final Map<String, latlng.LatLng> _locationDatabase = {
  'uttara': latlng.LatLng(23.8759, 90.3795),
  'uttara sector 3': latlng.LatLng(23.8789, 90.4158),
  'uttara sector 7': latlng.LatLng(23.8654, 90.3912),
  'dhanmondi': latlng.LatLng(23.7465, 90.3668),
  'dhanmondi 27': latlng.LatLng(23.7461, 90.3742),
  'gulshan': latlng.LatLng(23.7925, 90.4078),
  'gulshan 1': latlng.LatLng(23.7809, 90.4172),
  'gulshan 2': latlng.LatLng(23.7925, 90.4078),
  'mirpur': latlng.LatLng(23.8223, 90.3654),
  'mirpur 10': latlng.LatLng(23.8070, 90.3687),
  'mirpur 11': latlng.LatLng(23.8161, 90.3573),
  'banani': latlng.LatLng(23.7937, 90.4066),
  'motijheel': latlng.LatLng(23.7323, 90.4172),
  'kawran bazar': latlng.LatLng(23.7522, 90.3927),
  'dhaka airport': latlng.LatLng(23.8433, 90.3978),
  'shahbag': latlng.LatLng(23.7389, 90.3957),
  'farmgate': latlng.LatLng(23.7581, 90.3882),
  'mohakhali': latlng.LatLng(23.7808, 90.4067),
  'badda': latlng.LatLng(23.7808, 90.4265),
  'rampura': latlng.LatLng(23.7590, 90.4210),
  'bashundhara': latlng.LatLng(23.8223, 90.4276),
  'baridhara': latlng.LatLng(23.8103, 90.4225),
  'tejgaon': latlng.LatLng(23.7645, 90.3913),
  'new market': latlng.LatLng(23.7340, 90.3850),
  'elephant road': latlng.LatLng(23.7384, 90.3938),
  'old dhaka': latlng.LatLng(23.7104, 90.4074),
  'lalbagh': latlng.LatLng(23.7181, 90.3881),
  'sadarghat': latlng.LatLng(23.7104, 90.4074),
  'jatrabari': latlng.LatLng(23.7104, 90.4312),
  'agargaon': latlng.LatLng(23.7751, 90.3804),
  'mohammadpur': latlng.LatLng(23.7654, 90.3567),
  'khilgaon': latlng.LatLng(23.7516, 90.4292),
  'shantinagar': latlng.LatLng(23.7430, 90.4085),
  'purana paltan': latlng.LatLng(23.7372, 90.4159),
  'segunbagicha': latlng.LatLng(23.7430, 90.4011),
};

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _isMapLoading = true;
  bool _showSearchSuggestions = false;
  bool _isNavigationActive = false;

  latlng.LatLng? _currentLatLng;
  latlng.LatLng? _destinationLatLng;
  String _destinationName = "";
  List<String> _searchSuggestions = [];

  String _selectedRouteType = "Safest";
  double _distance = 0.0;
  int _time = 0;
  int _safetyScore = 95;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLatLng = latlng.LatLng(position.latitude, position.longitude);
          _isMapLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Location Error: $e");
      if (mounted) {
        setState(() {
          _currentLatLng = latlng.LatLng(23.8103, 90.4125);
          _isMapLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchSuggestions = [];
        _showSearchSuggestions = false;
      });
      return;
    }

    final suggestions = _locationDatabase.keys
        .where(
            (location) => location.toLowerCase().contains(query.toLowerCase()))
        .take(6)
        .toList();

    setState(() {
      _searchSuggestions = suggestions;
      _showSearchSuggestions = suggestions.isNotEmpty;
    });
  }

  void _navigateToLocation(String locationName) {
    final destination = _locationDatabase[locationName.toLowerCase()];
    if (destination == null || _currentLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Location not found in database'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _destinationLatLng = destination;
      _destinationName =
          locationName[0].toUpperCase() + locationName.substring(1);
      _showSearchSuggestions = false;
      _searchController.text = _destinationName;
      _searchFocus.unfocus();

      _distance = Geolocator.distanceBetween(
            _currentLatLng!.latitude,
            _currentLatLng!.longitude,
            _destinationLatLng!.latitude,
            _destinationLatLng!.longitude,
          ) /
          1000;

      _updateRouteStats(_selectedRouteType);
      _isNavigationActive = true;
    });

    _mapController.move(_destinationLatLng!, 14.0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.navigation, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Route set to $_destinationName',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _clearNavigation() {
    setState(() {
      _searchController.clear();
      _destinationLatLng = null;
      _destinationName = "";
      _isNavigationActive = false;
      _showSearchSuggestions = false;
      _distance = 0.0;
      _time = 0;
      _safetyScore = 95;
      _selectedRouteType = "Safest";
    });

    if (_currentLatLng != null) {
      _mapController.move(_currentLatLng!, 13.0);
    }
  }

  void _updateRouteStats(String type) {
    if (!_isNavigationActive || _distance == 0.0) return;

    setState(() {
      _selectedRouteType = type;
      if (type == "Safest") {
        _time = (_distance * 12).round() + 5;
        _safetyScore = 98;
      } else if (type == "Fastest") {
        _time = (_distance * 8).round();
        _safetyScore = 72;
      } else {
        _time = (_distance * 10).round();
        _safetyScore = 85;
      }
    });
  }

  void _startTrip() {
    if (_destinationLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Please select a destination first'),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Navigation Started',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Destination: $_destinationName',
                style: const TextStyle(fontSize: 13)),
            Text('Route Type: $_selectedRouteType',
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF5252), size: 28),
            SizedBox(width: 10),
            Text('SOS Activated',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Emergency contacts have been notified with your current location.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(color: Color(0xFF4FC3F7), fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: _buildHeader(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 25,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildMapContainer(),
                    ),
                  ),
                ),
                _buildDynamicBottomPanel(),
              ],
            ),
            if (_showSearchSuggestions)
              Positioned(
                top: 135,
                left: 24,
                right: 24,
                child: _buildSuggestionsDropdown(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SafeStep',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              _isNavigationActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF4FC3F7).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation,
                            color: Color(0xFF4FC3F7),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _destinationName,
                            style: const TextStyle(
                              color: Color(0xFF4FC3F7),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'Where to?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF4FC3F7).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.my_location,
            color: Color(0xFF4FC3F7),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocus.hasFocus
              ? const Color(0xFF4FC3F7)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _navigateToLocation(value);
          }
        },
        decoration: InputDecoration(
          hintText: 'Search destination...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.4),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.4),
                    size: 20,
                  ),
                  onPressed: _clearNavigation,
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildSuggestionsDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: _searchSuggestions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withOpacity(0.05),
            indent: 50,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final suggestion = _searchSuggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToLocation(suggestion),
                splashColor: const Color(0xFF4FC3F7).withOpacity(0.1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4FC3F7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFF4FC3F7),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion[0].toUpperCase() + suggestion.substring(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.2),
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    if (_isMapLoading) {
      return Container(
        color: const Color(0xFF0D0D1E),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 45,
                height: 45,
                child: CircularProgressIndicator(
                  color: const Color(0xFF4FC3F7),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Loading map...',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng ?? latlng.LatLng(23.8103, 90.4125),
        initialZoom: 13.0,
        minZoom: 10.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
          userAgentPackageName: 'com.example.safe_step',
        ),
        if (_currentLatLng != null || _destinationLatLng != null)
          MarkerLayer(
            markers: [
              if (_currentLatLng != null)
                Marker(
                  point: _currentLatLng!,
                  width: 45,
                  height: 45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4FC3F7).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              if (_destinationLatLng != null)
                Marker(
                  point: _destinationLatLng!,
                  width: 45,
                  height: 45,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5252).withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDynamicBottomPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, -8),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 22),
            if (_isNavigationActive) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.shield_outlined,
                      value: '$_safetyScore%',
                      label: 'Safety',
                      color: _safetyScore > 90
                          ? const Color(0xFF66BB6A)
                          : _safetyScore > 75
                              ? const Color(0xFFFFA726)
                              : const Color(0xFFEF5350),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.straighten,
                      value: '${_distance.toStringAsFixed(1)}',
                      label: 'Distance (km)',
                      color: const Color(0xFF4FC3F7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.schedule,
                      value: '$_time',
                      label: 'Time (min)',
                      color: const Color(0xFFAB47BC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Route Type',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: ["Safest", "Fastest", "Balanced"].map((type) {
                  bool isSelected = _selectedRouteType == type;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _updateRouteStats(type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF4FC3F7)
                                : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4FC3F7)
                                  : Colors.white.withOpacity(0.1),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF4FC3F7).withOpacity(0.7),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Enter a destination to begin',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: ElevatedButton(
                    onPressed: _isNavigationActive ? _startTrip : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNavigationActive
                          ? const Color(0xFF4FC3F7)
                          : Colors.white.withOpacity(0.08),
                      disabledBackgroundColor: Colors.white.withOpacity(0.08),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isNavigationActive
                              ? Icons.navigation
                              : Icons.play_arrow,
                          size: 19,
                          color: _isNavigationActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'START TRIP',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                            color: _isNavigationActive
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onLongPress: _triggerSOS,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFF5252),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'SOS',
                        style: TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
