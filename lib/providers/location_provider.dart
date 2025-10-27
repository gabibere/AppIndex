import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier, WidgetsBindingObserver {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;
  bool _permissionGranted = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get permissionGranted => _permissionGranted;

  // Initialize location services
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // Add lifecycle observer to detect app resume
      WidgetsBinding.instance.addObserver(this);

      // Check if location services are enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
            'Location services are disabled. Please enable them in settings.');
        return;
      }

      // Check permissions
      LocationPermission permission =
          await LocationService.checkLocationPermission();
      if (permission == LocationPermission.denied) {
        _permissionGranted = false;
        _setError('Location permission is required to use this feature.');
      } else if (permission == LocationPermission.deniedForever) {
        _permissionGranted = false;
        _setError(
            'Location permission is permanently denied. Please enable it in app settings.');
      } else {
        _permissionGranted = true;
        _clearError();
      }
    } catch (e) {
      _setError('Failed to initialize location services: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check permissions when app resumes
      _recheckPermissionsOnResume();
    }
  }

  // Re-check permissions when app resumes
  Future<void> _recheckPermissionsOnResume() async {
    try {
      // Check if location services are now enabled
      bool serviceEnabled = await LocationService.isLocationServiceEnabled();
      if (serviceEnabled) {
        // Re-check permissions
        LocationPermission permission =
            await LocationService.checkLocationPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _permissionGranted = false;
        } else {
          _permissionGranted = true;
          _clearError();
        }

        // If permissions are now granted and we don't have location, try to get it
        if (_permissionGranted && _currentPosition == null) {
          await getCurrentLocation();
        }
      }
    } catch (e) {
      // Silently handle errors during resume check
    }
  }

  // Dispose lifecycle observer
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Request location permission
  Future<bool> requestPermission() async {
    _setLoading(true);
    try {
      LocationPermission permission =
          await LocationService.requestLocationPermission();

      if (permission == LocationPermission.denied) {
        _permissionGranted = false;
        _setError('Location permission denied');
        return false;
      } else if (permission == LocationPermission.deniedForever) {
        _permissionGranted = false;
        _setError(
            'Location permission permanently denied. Please enable it in app settings.');
        return false;
      } else {
        _permissionGranted = true;
        _clearError();
        return true;
      }
    } catch (e) {
      _setError('Failed to request location permission: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get current location
  Future<bool> getCurrentLocation() async {
    if (!_permissionGranted) {
      _setError('Location permission not granted');
      return false;
    }

    _setLoading(true);
    try {
      Position? position = await LocationService.getCurrentPosition();

      if (position != null) {
        _currentPosition = position;

        // Get address from coordinates
        String? address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _currentAddress = address;

        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to get current location');
        return false;
      }
    } catch (e) {
      // Check if it's a location services disabled error
      if (e.toString().contains('Location services are disabled')) {
        _setError(
            'Location services are disabled. Please enable them in your device settings.');
        // Automatically try to open location settings
        await LocationService.openLocationSettings();
      } else {
        _setError('Error getting location: $e');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get location from address
  Future<bool> getLocationFromAddress(String address) async {
    _setLoading(true);
    try {
      Position? position =
          await LocationService.getCoordinatesFromAddress(address);

      if (position != null) {
        _currentPosition = position;
        _currentAddress = address;
        _clearError();
        notifyListeners();
        return true;
      } else {
        _setError('Could not find location for address: $address');
        return false;
      }
    } catch (e) {
      _setError('Error getting location from address: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate distance to a point
  double? calculateDistanceTo(double latitude, double longitude) {
    if (_currentPosition == null) return null;

    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      latitude,
      longitude,
    );
  }

  // Open location settings
  Future<void> openLocationSettings() async {
    await LocationService.openLocationSettings();
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await LocationService.openAppSettings();
  }

  // Clear location data
  void clearLocation() {
    _currentPosition = null;
    _currentAddress = null;
    _clearError();
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
