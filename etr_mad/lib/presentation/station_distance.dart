import 'dart:math' as math;

import '../models/station.dart';

double distanceInMeters({
  required double latitude,
  required double longitude,
  required Station station,
}) {
  const earthRadius = 6371000.0;
  final latitudeDelta = _radians(station.latitude - latitude);
  final longitudeDelta = _radians(station.longitude - longitude);
  final startLatitude = _radians(latitude);
  final endLatitude = _radians(station.latitude);
  final a = math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(startLatitude) *
          math.cos(endLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(a));
}

List<Station> sortStationsByDistance({
  required Iterable<Station> stations,
  required double? latitude,
  required double? longitude,
}) {
  final result = stations.toList();
  if (latitude == null || longitude == null) return result;
  result.sort(
    (a, b) => distanceInMeters(
      latitude: latitude,
      longitude: longitude,
      station: a,
    ).compareTo(
      distanceInMeters(
        latitude: latitude,
        longitude: longitude,
        station: b,
      ),
    ),
  );
  return result;
}

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m away';
  return '${(meters / 1000).toStringAsFixed(1)} km away';
}

double _radians(double degrees) => degrees * math.pi / 180;
