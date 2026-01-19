import 'package:latlong2/latlong.dart' as latlng;
import 'dart:math' as math;

/// Utility class for map-related operations
class MapService {
  // Dhaka Coordinates (default location)
  static const double dhakaCenterLatitude = 23.7810672;
  static const double dhakaCenterLongitude = 90.2548716;
  static const String dhakaLocationName = 'Dhaka, Bangladesh';

  // OpenStreetMap tile URLs (with subdomains for load balancing)
  static const String osmTileUrl =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Alternative tile providers (more lenient with usage policy)
  static const String alternativeTileUrl1 =
      'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
  static const String alternativeTileUrl2 =
      'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png';

  // Common Dhaka locations for reference
  static final Map<String, latlng.LatLng> dhakaLocations = {
    'Dhaka Center': const latlng.LatLng(23.8103, 90.4125),
    'Gulshan': const latlng.LatLng(23.7934, 90.4304),
    'Banani': const latlng.LatLng(23.8188, 90.3936),
    'Dhanmondi': const latlng.LatLng(23.7626, 90.3739),
    'Uttara': const latlng.LatLng(23.8852, 90.3949),
    'Mirpur': const latlng.LatLng(23.8103, 90.3532),
    'Motijheel': const latlng.LatLng(23.7593, 90.3888),
    'Shyamoli': const latlng.LatLng(23.8034, 90.3273),
  };

  /// Get default Dhaka location
  static latlng.LatLng getDhakaCenter() {
    return const latlng.LatLng(dhakaCenterLatitude, dhakaCenterLongitude);
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a =
        (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRad(lat1)) *
            Math.cos(_toRad(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    final distance = R * c;
    return distance;
  }

  static double _toRad(double degree) {
    return degree * (3.14159265359 / 180);
  }

  /// Check if location is within Dhaka bounds
  /// Approximately 23.6 to 23.95 latitude, 90.2 to 90.5 longitude
  static bool isWithinDhaka(double latitude, double longitude) {
    return latitude >= 23.6 &&
        latitude <= 23.95 &&
        longitude >= 90.2 &&
        longitude <= 90.5;
  }

  /// Format location string for display
  static String formatLocationString(
    double latitude,
    double longitude,
    String? locationName,
  ) {
    if (locationName != null && locationName.isNotEmpty) {
      return locationName;
    }
    return '$latitude, $longitude';
  }

  /// Get OpenStreetMap tile URL with proper headers
  static String getTileUrl() {
    return osmTileUrl;
  }

  /// Get tile subdomains for load balancing
  static List<String> getTileSubdomains() {
    return ['a', 'b', 'c'];
  }

  /// Get user agent for tiles
  static String getUserAgent() {
    return 'MediShare/1.0.0 (Medical Donation App)';
  }
}

/// Simple Math class for trigonometric operations
class Math {
  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static double sqrt(double x) => _sqrt(x);
  static double atan2(double y, double x) => _atan2(y, x);

  static double _sin(double x) {
    return dart_sin(x);
  }

  static double _cos(double x) {
    return dart_cos(x);
  }

  static double _sqrt(double x) {
    return dart_sqrt(x);
  }

  static double _atan2(double y, double x) {
    return dart_atan2(y, x);
  }
}

double dart_sin(double x) => math.sin(x);
double dart_cos(double x) => math.cos(x);
double dart_sqrt(double x) => math.sqrt(x);
double dart_atan2(double y, double x) => math.atan2(y, x);
