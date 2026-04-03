import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _searchController = TextEditingController();

  LatLng? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  late AnimationController _pulseController;

  bool _isWarningActive = false;
  DateTime _lastWarningTime =
      DateTime.now().subtract(const Duration(seconds: 10));

  final List<LatLng> _barriers = [];
  bool _barriersGenerated = false;

  final List<LatLng> _footprintPath = [];
  double _currentHeading = 0.0;

  // Routing State
  LatLng? _destination;
  List<LatLng> _routePath = [];
  double _distanceToDestination = 0.0;
  bool _isRouting = false;

  // Search Autocomplete State
  Timer? _debounce;
  List<dynamic> _suggestions = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _initTTS();
    _initHighPrecisionTracking();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-IN");
    await flutterTts.setSpeechRate(0.45);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);

    await flutterTts.speak("Nav Assist Active. Tracking your location.");
  }

  Position _getMeerutFallback() {
    return Position(
      latitude: 28.9845,
      longitude: 77.7064,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _initHighPrecisionTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      // Step 1: Try to get last known to instantly show their actual area
      Position? lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _handleNewLocation(lastPos);
      }

      // Step 2: Request precise current location with a longer timeout for indoor/web users
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy
            .high, // 'high' is more reliable than 'bestForNavigation' indoors
        timeLimit: const Duration(seconds: 15),
      );
      _handleNewLocation(position);
    } catch (e) {
      // Only fallback if everything fails
      if (_currentPosition == null) {
        _handleNewLocation(_getMeerutFallback());
        await flutterTts.speak("GPS signal weak. Using fallback location.");
      }
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(
      (Position pos) => _handleNewLocation(pos),
    );
  }

  void _handleNewLocation(Position pos) {
    if (!mounted) return;

    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    setState(() {
      _currentPosition = newPoint;
      _currentHeading = pos.heading;

      if (_footprintPath.isEmpty ||
          const Distance().as(LengthUnit.Meter, _footprintPath.last, newPoint) >
              0.1) {
        _footprintPath.add(newPoint);
        if (_footprintPath.length > 500) _footprintPath.removeAt(0);
      }

      if (!_barriersGenerated) _generateDummyBarriers(pos);

      // Update distance to destination if active
      if (_destination != null) {
        _distanceToDestination = const Distance()
            .as(LengthUnit.Meter, _currentPosition!, _destination!);
      }
    });

    // Only auto-follow if we are not looking at a route overview
    if (_destination == null) {
      _mapController.moveAndRotate(newPoint, 19.0, _currentHeading);
    }

    _checkObstacles();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _isSearching = true);
      try {
        // Use Nominatim API for highly accurate, address-rich autocomplete
        final encodedQuery = Uri.encodeComponent(query);
        String url =
            'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=8';

        // Bias towards current location
        if (_currentPosition != null) {
          double lat = _currentPosition!.latitude;
          double lon = _currentPosition!.longitude;
          double offset = 0.5; // roughly 50km viewbox
          url +=
              '&viewbox=${lon - offset},${lat + offset},${lon + offset},${lat - offset}&bounded=0';
        }

        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          final List<dynamic> data = json.decode(res.body);
          setState(() {
            _suggestions = data;
          });
        }
      } catch (e) {
        debugPrint("Autocomplete error: $e");
      } finally {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _routeToDestination(double lat, double lon, String title) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _isRouting = true;
      _destination = LatLng(lat, lon);
      _searchController.text = title;
    });

    await flutterTts.speak("Routing to $title");

    try {
      final routeUrl = Uri.parse(
          'http://router.project-osrm.org/route/v1/walking/${_currentPosition!.longitude},${_currentPosition!.latitude};$lon,$lat?geometries=geojson');
      final routeRes = await http.get(routeUrl);

      if (routeRes.statusCode == 200) {
        final routeData = json.decode(routeRes.body);
        if (routeData['routes'] != null && routeData['routes'].isNotEmpty) {
          final geometry =
              routeData['routes'][0]['geometry']['coordinates'] as List;

          setState(() {
            _routePath =
                geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
            _distanceToDestination =
                routeData['routes'][0]['distance'].toDouble();
          });

          // Frame the map to show the route
          final bounds =
              LatLngBounds.fromPoints([_currentPosition!, _destination!]);
          _mapController.fitCamera(CameraFit.bounds(
              bounds: bounds, padding: const EdgeInsets.all(80)));

          await flutterTts.speak(
              "Route found. Distance is ${_distanceToDestination.toInt()} meters. Follow the neon purple line.");
        }
      }
    } catch (e) {
      await flutterTts.speak("Network error while routing.");
    } finally {
      if (mounted) setState(() => _isRouting = false);
    }
  }

  Future<void> _searchDestination(String query) async {
    if (query.isEmpty || _currentPosition == null) return;
    FocusScope.of(context).unfocus();

    setState(() => _isRouting = true);
    await flutterTts.speak("Searching for $query");

    try {
      // 1. Geocode via Nominatim
      final encodedQuery = Uri.encodeComponent(query);
      final geocodeUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1');
      final geoRes = await http.get(geocodeUrl);

      if (geoRes.statusCode == 200) {
        final data = json.decode(geoRes.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          _destination = LatLng(lat, lon);

          // 2. Fetch Route via OSRM
          final routeUrl = Uri.parse(
              'http://router.project-osrm.org/route/v1/walking/${_currentPosition!.longitude},${_currentPosition!.latitude};$lon,$lat?geometries=geojson');
          final routeRes = await http.get(routeUrl);

          if (routeRes.statusCode == 200) {
            final routeData = json.decode(routeRes.body);
            if (routeData['routes'] != null && routeData['routes'].isNotEmpty) {
              final geometry =
                  routeData['routes'][0]['geometry']['coordinates'] as List;
              _routePath =
                  geometry.map((coord) => LatLng(coord[1], coord[0])).toList();
              _distanceToDestination =
                  routeData['routes'][0]['distance'].toDouble();

              // Frame the map to show the route
              final bounds =
                  LatLngBounds.fromPoints([_currentPosition!, _destination!]);
              _mapController.fitCamera(CameraFit.bounds(
                  bounds: bounds, padding: const EdgeInsets.all(80)));

              await flutterTts.speak(
                  "Route found. Distance is ${_distanceToDestination.toInt()} meters. Follow the neon purple line.");
            }
          }
        } else {
          await flutterTts
              .speak("Destination not found. Try a different name.");
        }
      }
    } catch (e) {
      await flutterTts.speak("Network error while routing.");
    } finally {
      if (mounted) setState(() => _isRouting = false);
    }
  }

  void _cancelRoute() {
    setState(() {
      _destination = null;
      _routePath.clear();
      _distanceToDestination = 0.0;
      _searchController.clear();
      if (_currentPosition != null) {
        _mapController.moveAndRotate(_currentPosition!, 19.0, _currentHeading);
      }
    });
    flutterTts.speak("Route cancelled. Resuming free roaming.");
  }

  void _generateDummyBarriers(Position pos) {
    _barriers.clear();
    _barriers.add(LatLng(pos.latitude + 0.0001, pos.longitude + 0.0001));
    _barriers.add(LatLng(pos.latitude - 0.0001, pos.longitude - 0.00005));
    _barriersGenerated = true;
  }

  void _checkObstacles() async {
    if (_currentPosition == null) return;

    for (var barrier in _barriers) {
      final distance =
          const Distance().as(LengthUnit.Meter, _currentPosition!, barrier);

      if (distance < 8 &&
          DateTime.now().difference(_lastWarningTime).inSeconds > 4) {
        _lastWarningTime = DateTime.now();
        setState(() => _isWarningActive = true);

        try {
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 800);
          }
        } catch (_) {}

        String warningMsg = "Obstacle ${distance.toInt()} meters ahead.";
        if (distance < 3) warningMsg = "Danger. Immediate barrier. Stop now.";

        await flutterTts.speak(warningMsg);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isWarningActive = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _pulseController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Nav Assist Map',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController.moveAndRotate(
                    _currentPosition!, 19.0, _currentHeading);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_currentPosition == null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppTheme.primaryBlue),
                  const SizedBox(height: 20),
                  const Text("Acquiring High-Precision GPS...",
                      style: TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () => _handleNewLocation(_getMeerutFallback()),
                    child: const Text("Skip GPS & Load Meerut Map",
                        style: TextStyle(color: AppTheme.primaryBlue)),
                  ),
                ],
              ),
            )
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition!,
                initialZoom: 19.0,
                maxZoom: 22.0, // Allow extreme zoom
              ),
              children: [
                // Ultra-HD Satellite + Labels (Google Hybrid Map)
                TileLayer(
                  urlTemplate:
                      'https://{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
                  subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                  userAgentPackageName: 'com.navassist.app',
                  maxNativeZoom: 21,
                  maxZoom: 22,
                ),
                // Footstep trail (Cyan)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _footprintPath,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.6),
                      strokeWidth: 6,
                    ),
                    // Route path (Neon Purple/Pink)
                    if (_routePath.isNotEmpty)
                      Polyline(
                        points: _routePath,
                        color: Colors.purpleAccent,
                        strokeWidth: 8,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (var barrier in _barriers)
                      Marker(
                        point: barrier,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.warning_amber_rounded,
                            color: Colors.orangeAccent, size: 30),
                      ),
                    if (_destination != null)
                      Marker(
                        point: _destination!,
                        width: 50,
                        height: 50,
                        child: const Icon(Icons.location_on,
                            color: Colors.purpleAccent, size: 40),
                      ),
                    Marker(
                      point: _currentPosition!,
                      width: 60,
                      height: 60,
                      child: _buildUserPointer(),
                    ),
                  ],
                ),
              ],
            ),

          // Search Bar Overlay
          if (_currentPosition != null) _buildSearchBar(),

          // Danger Overlay
          if (_isWarningActive) _buildDangerPulse(),

          // Distance HUD
          if (_currentPosition != null) _buildHUD(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                color: AppTheme.glassPanel,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.primaryBlue),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Enter destination (e.g. Hospital)",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchDestination,
                  ),
                ),
                if (_isRouting || _isSearching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.primaryBlue),
                  )
                else if (_destination != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _cancelRoute,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryBlue),
                    onPressed: () => _searchDestination(_searchController.text),
                  ),
              ],
            ),
          ),

          // --- AUTOCOMPLETE SUGGESTIONS DROPDOWN ---
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppTheme.glassPanel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final feature = _suggestions[index];
                    final address = feature['address'] ?? {};

                    String title = feature['name'] ??
                        address['name'] ??
                        address['road'] ??
                        feature['display_name']?.split(',').first ??
                        'Location';
                    String subtitle = feature['display_name'] ?? '';

                    // Get coordinates
                    double lat = double.tryParse(feature['lat'] ?? '0') ?? 0.0;
                    double lon = double.tryParse(feature['lon'] ?? '0') ?? 0.0;

                    return ListTile(
                      leading:
                          const Icon(Icons.location_on, color: Colors.white70),
                      title: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        _routeToDestination(lat, lon, title);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserPointer() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_currentHeading * 3.14159 / 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 30 + (10 * _pulseController.value),
                height: 30 + (10 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              const Icon(
                Icons.navigation,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDangerPulse() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent, width: 10),
          color: Colors.red.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildHUD() {
    bool hasRoute = _destination != null;
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: AppTheme.glassPanel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: hasRoute
                    ? Colors.purpleAccent.withValues(alpha: 0.5)
                    : Colors.white10),
            boxShadow: [
              BoxShadow(
                color: (hasRoute ? Colors.purpleAccent : Colors.black)
                    .withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasRoute)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.directions_walk,
                      color: Colors.purpleAccent, size: 28),
                  Text(
                    "Distance: ${_distanceToDestination > 1000 ? (_distanceToDestination / 1000).toStringAsFixed(1) + ' km' : _distanceToDestination.toInt().toString() + ' m'}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, color: AppTheme.primaryBlue),
                  SizedBox(width: 10),
                  Text(
                    "Area Scanning Active",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
