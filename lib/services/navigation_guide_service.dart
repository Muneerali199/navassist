import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'preferences_service.dart';

/// Real-time turn-by-turn voice navigation guidance service.
/// Parses OSRM route steps and provides voice instructions
/// as the user moves along the route.
class NavigationGuideService {
  static final NavigationGuideService _instance =
      NavigationGuideService._internal();
  factory NavigationGuideService() => _instance;
  NavigationGuideService._internal();

  final FlutterTts _tts = FlutterTts();
  final PreferencesService _prefs = PreferencesService();
  final Distance _distCalc = const Distance();

  bool _isInitialized = false;
  bool _isNavigating = false;
  Timer? _announcementTimer;

  // Route data
  List<RouteStep> _steps = [];
  List<LatLng> _fullRoute = [];
  int _currentStepIndex = 0;
  LatLng? _destination;

  // Thresholds
  static const double _stepCompleteThreshold = 25.0; // meters - mark step done
  static const double _arrivalThreshold = 20.0; // meters - arrival
  static const double _offRouteThreshold = 50.0; // meters - recalculate
  static const double _approachAnnounceDistance = 100.0; // meters
  static const double _immediateTurnDistance = 30.0; // meters

  // State tracking
  DateTime _lastAnnouncementTime = DateTime.now().subtract(const Duration(seconds: 30));
  double _lastAnnouncedDistance = 0;
  bool _hasAnnouncedApproach = false;
  int _offRouteCount = 0;

  // Callbacks
  Function(String instruction)? onInstructionUpdate;
  Function(double distanceToNext, String maneuver)? onStepProgress;
  Function()? onArrival;
  Function()? onOffRoute;

  bool get isNavigating => _isNavigating;
  int get currentStepIndex => _currentStepIndex;
  int get totalSteps => _steps.length;
  List<LatLng> get fullRoute => _fullRoute;

  RouteStep? get currentStep =>
      _currentStepIndex < _steps.length ? _steps[_currentStepIndex] : null;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final lang = _prefs.currentLanguage;
    await _tts.setLanguage(lang);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);

    // Use the best available TTS engine
    await _tts.awaitSpeakCompletion(true);

    _isInitialized = true;
    dev.log("NavigationGuideService initialized with language: $lang");
  }

  Future<void> updateLanguage() async {
    final lang = _prefs.currentLanguage;
    await _tts.setLanguage(lang);
    dev.log("NavigationGuideService language updated to: $lang");
  }

  /// Fetch route with full step-by-step instructions from OSRM
  Future<NavigationRoute?> fetchRoute(LatLng origin, LatLng destination) async {
    _destination = destination;

    try {
      final url = Uri.parse(
          'http://router.project-osrm.org/route/v1/walking/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?geometries=geojson&overview=full&steps=true');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry']['coordinates'] as List;
          final totalDistance = route['distance'].toDouble();
          final totalDuration = route['duration'].toDouble();

          _fullRoute = geometry.map((c) => LatLng(c[1], c[0])).toList();

          // Parse steps from the first leg
          _steps = [];
          if (route['legs'] != null && (route['legs'] as List).isNotEmpty) {
            final leg = route['legs'][0];
            if (leg['steps'] != null) {
              for (var step in leg['steps']) {
                final stepGeometry = step['geometry']['coordinates'] as List;
                final stepPoints =
                    stepGeometry.map((c) => LatLng(c[1], c[0])).toList();

                final maneuver = step['maneuver'] ?? {};
                final maneuverType = maneuver['type'] ?? 'continue';
                final modifier = maneuver['modifier'] ?? '';
                final maneuverLocation = maneuver['location'] as List?;

                LatLng? maneuverPoint;
                if (maneuverLocation != null && maneuverLocation.length >= 2) {
                  maneuverPoint = LatLng(maneuverLocation[1], maneuverLocation[0]);
                }

                _steps.add(RouteStep(
                  instruction: _buildInstruction(maneuverType, modifier,
                      step['name'] ?? '', step['distance']?.toDouble() ?? 0),
                  maneuverType: maneuverType,
                  modifier: modifier,
                  distance: step['distance']?.toDouble() ?? 0,
                  duration: step['duration']?.toDouble() ?? 0,
                  name: step['name'] ?? '',
                  points: stepPoints,
                  maneuverPoint: maneuverPoint ?? (stepPoints.isNotEmpty ? stepPoints.first : origin),
                ));
              }
            }
          }

          // Fallback: if no parsed steps, create a simple direct route
          if (_steps.isEmpty) {
            _steps = [
              RouteStep(
                instruction: _prefs.translate('continue_straight'),
                maneuverType: 'continue',
                modifier: 'straight',
                distance: totalDistance,
                duration: totalDuration,
                name: '',
                points: _fullRoute,
                maneuverPoint: origin,
              )
            ];
          }

          return NavigationRoute(
            points: _fullRoute,
            steps: _steps,
            totalDistance: totalDistance,
            totalDuration: totalDuration,
          );
        }
      }
    } catch (e) {
      dev.log("Route fetch error: $e");
    }

    return null;
  }

  /// Start navigating along a previously fetched route
  Future<void> startNavigation() async {
    if (_steps.isEmpty || _destination == null) return;

    await initialize();
    _isNavigating = true;
    _currentStepIndex = 0;
    _offRouteCount = 0;
    _hasAnnouncedApproach = false;

    // Announce first instruction
    final firstStep = _steps[0];
    String announcement = _prefs.translate('route_found');
    if (firstStep.distance > 0) {
      if (firstStep.distance > 1000) {
        announcement += ' ${_prefs.translateWith('distance_km', (firstStep.distance / 1000).toStringAsFixed(1))}';
      } else {
        announcement += ' ${_prefs.translateWithInt('distance_m', firstStep.distance.toInt())}';
      }
    }
    await _speak(announcement);

    // After a brief pause, announce the first turn
    await Future.delayed(const Duration(seconds: 3));
    if (_isNavigating && _steps.isNotEmpty) {
      await _speak(_steps[0].instruction);
    }
  }

  /// Update position during navigation - call this frequently
  void updatePosition(LatLng currentPosition) {
    if (!_isNavigating || _steps.isEmpty) return;

    // Check arrival at destination
    if (_destination != null) {
      final distToDest = _distCalc.as(LengthUnit.Meter, currentPosition, _destination!);
      if (distToDest < _arrivalThreshold) {
        _announceArrival();
        return;
      }
    }

    // Grab current step
    if (_currentStepIndex >= _steps.length) return;
    final step = _steps[_currentStepIndex];

    // Distance to the maneuver point of the current step
    final distToManeuver = _distCalc.as(LengthUnit.Meter, currentPosition, step.maneuverPoint);

    // Check if we have completed this step
    if (_currentStepIndex < _steps.length - 1) {
      final nextStep = _steps[_currentStepIndex + 1];
      final distToNextManeuver =
          _distCalc.as(LengthUnit.Meter, currentPosition, nextStep.maneuverPoint);

      // If we're closer to the next step than the completion threshold, advance
      if (distToNextManeuver < _stepCompleteThreshold || distToManeuver < 10) {
        _advanceStep(currentPosition);
        return;
      }
    }

    // Approach announcements for the current step's end / next turn
    if (_currentStepIndex < _steps.length - 1) {
      final nextStep = _steps[_currentStepIndex + 1];
      final distToNextManeuver =
          _distCalc.as(LengthUnit.Meter, currentPosition, nextStep.maneuverPoint);

      // Announce approach at ~100m
      if (distToNextManeuver < _approachAnnounceDistance && !_hasAnnouncedApproach) {
        _hasAnnouncedApproach = true;
        final instruction = '${nextStep.instruction} ${_prefs.translateWithInt('in_meters', distToNextManeuver.toInt())}';
        _announceIfReady(instruction, minInterval: 8);
      }

      // Announce imminent turn at ~30m
      if (distToNextManeuver < _immediateTurnDistance) {
        _announceIfReady(nextStep.instruction, minInterval: 6);
      }
    }

    // Check if off-route
    final distToRoute = _getDistanceToNearestRoutePoint(currentPosition);
    if (distToRoute > _offRouteThreshold) {
      _offRouteCount++;
      if (_offRouteCount > 3) {
        onOffRoute?.call();
        _announceIfReady(_prefs.translate('recalculating'), minInterval: 15);
        _offRouteCount = 0;
      }
    } else {
      _offRouteCount = 0;
    }

    // Update callback
    onStepProgress?.call(
      _currentStepIndex < _steps.length - 1
          ? _distCalc.as(LengthUnit.Meter, currentPosition, _steps[_currentStepIndex + 1].maneuverPoint)
          : _distCalc.as(LengthUnit.Meter, currentPosition, _destination!),
      step.maneuverType,
    );
  }

  void _advanceStep(LatLng currentPosition) {
    _currentStepIndex++;
    _hasAnnouncedApproach = false;
    _lastAnnouncedDistance = 0;

    if (_currentStepIndex >= _steps.length) {
      _announceArrival();
      return;
    }

    final step = _steps[_currentStepIndex];
    _speak(step.instruction);
    onInstructionUpdate?.call(step.instruction);
  }

  void _announceArrival() {
    _speak(_prefs.translate('arrived'));
    _isNavigating = false;
    onArrival?.call();
  }

  Future<void> _announceIfReady(String text, {int minInterval = 6}) async {
    final now = DateTime.now();
    if (now.difference(_lastAnnouncementTime).inSeconds >= minInterval) {
      _lastAnnouncementTime = now;
      await _speak(text);
      onInstructionUpdate?.call(text);
    }
  }

  double _getDistanceToNearestRoutePoint(LatLng position) {
    if (_fullRoute.isEmpty) return 0;

    double minDist = double.infinity;
    // Only check nearby route points for performance
    final startIdx = max(0, _currentStepIndex * 5 - 10);
    final endIdx = min(_fullRoute.length, startIdx + 50);

    for (int i = startIdx; i < endIdx; i++) {
      final dist = _distCalc.as(LengthUnit.Meter, position, _fullRoute[i]);
      if (dist < minDist) minDist = dist;
    }
    return minDist;
  }

  String _buildInstruction(String type, String modifier, String name, double distance) {
    String instruction = '';
    final streetName = name.isNotEmpty ? ' ($name)' : '';

    switch (type) {
      case 'turn':
        if (modifier.contains('left')) {
          instruction = _prefs.translate('turn_left');
        } else if (modifier.contains('right')) {
          instruction = _prefs.translate('turn_right');
        } else {
          instruction = _prefs.translate('continue_straight');
        }
        break;
      case 'new name':
      case 'continue':
        instruction = _prefs.translate('continue_straight');
        break;
      case 'merge':
      case 'fork':
        if (modifier.contains('left')) {
          instruction = _prefs.translate('slight_left');
        } else if (modifier.contains('right')) {
          instruction = _prefs.translate('slight_right');
        } else {
          instruction = _prefs.translate('continue_straight');
        }
        break;
      case 'end of road':
        if (modifier.contains('left')) {
          instruction = _prefs.translate('turn_left');
        } else {
          instruction = _prefs.translate('turn_right');
        }
        break;
      case 'depart':
        instruction = _prefs.translate('continue_straight');
        break;
      case 'arrive':
        instruction = _prefs.translate('arrived');
        break;
      case 'roundabout':
      case 'rotary':
        instruction = _prefs.translate('continue_straight');
        break;
      default:
        instruction = _prefs.translate('continue_straight');
    }

    return '$instruction$streetName';
  }

  Future<void> _speak(String text) async {
    if (!_isInitialized) await initialize();
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      dev.log("TTS Error: $e");
    }
  }

  /// Speak any arbitrary text (exposed for other services)
  Future<void> speakText(String text) async {
    await _speak(text);
  }

  void stopNavigation() {
    _isNavigating = false;
    _steps.clear();
    _fullRoute.clear();
    _currentStepIndex = 0;
    _destination = null;
    _announcementTimer?.cancel();
    _tts.stop();
  }

  void dispose() {
    stopNavigation();
    _tts.stop();
  }
}

class RouteStep {
  final String instruction;
  final String maneuverType;
  final String modifier;
  final double distance;
  final double duration;
  final String name;
  final List<LatLng> points;
  final LatLng maneuverPoint;

  RouteStep({
    required this.instruction,
    required this.maneuverType,
    required this.modifier,
    required this.distance,
    required this.duration,
    required this.name,
    required this.points,
    required this.maneuverPoint,
  });
}

class NavigationRoute {
  final List<LatLng> points;
  final List<RouteStep> steps;
  final double totalDistance;
  final double totalDuration;

  NavigationRoute({
    required this.points,
    required this.steps,
    required this.totalDistance,
    required this.totalDuration,
  });
}
