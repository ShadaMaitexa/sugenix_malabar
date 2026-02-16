import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PlatformLocationService {
  // Get current location with web compatibility
  static Future<Position?> getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // For web, we'll use a simplified approach
        // In production, you might want to use a web-specific geolocation package
        return Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      } else {
        // For mobile, use the standard geolocator
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            return null;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          return null;
        }

        // Use lower accuracy if high accuracy fails (works better without SIM/WiFi)
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
        } catch (e) {
          // Fallback to lower accuracy if high accuracy fails (e.g., no SIM, no WiFi)
          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
              timeLimit: const Duration(seconds: 10),
            );
          } catch (e2) {
            // Last resort: use low accuracy
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 10),
            );
          }
        }
      }
    } catch (e) {
      return null;
    }
  }

  // Check location permission
  static Future<bool> hasLocationPermission() async {
    try {
      if (kIsWeb) {
        // Web doesn't have traditional permissions
        return true;
      } else {
        LocationPermission permission = await Geolocator.checkPermission();
        return permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always;
      }
    } catch (e) {
      return false;
    }
  }

  // Request location permission
  static Future<bool> requestLocationPermission() async {
    try {
      if (kIsWeb) {
        // Web doesn't have traditional permissions
        return true;
      } else {
        PermissionStatus status = await Permission.location.request();
        return status == PermissionStatus.granted;
      }
    } catch (e) {
      return false;
    }
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // For both web and mobile, create a Google Maps link
      // You can enhance this by using a geocoding API service
      final mapsUrl = 'https://maps.google.com/?q=$latitude,$longitude';
      
      // Return formatted location string with coordinates
      return 'Latitude: ${latitude.toStringAsFixed(6)}, Longitude: ${longitude.toStringAsFixed(6)}\n'
             'Map: $mapsUrl';
    } catch (e) {
      return 'Latitude: ${latitude.toStringAsFixed(6)}, Longitude: ${longitude.toStringAsFixed(6)}';
    }
  }
}
