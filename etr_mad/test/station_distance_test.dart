import 'package:flutter_test/flutter_test.dart';

import 'package:etr_mad/models/station.dart';
import 'package:etr_mad/presentation/station_distance.dart';

void main() {
  const nearby = Station(
    id: 'nearby',
    name: 'Nearby',
    latitude: 15.0005,
    longitude: 120,
  );
  const far = Station(
    id: 'far',
    name: 'Far',
    latitude: 16,
    longitude: 120,
  );

  test('calculates a useful distance and formats it', () {
    final distance = distanceInMeters(
      latitude: 15,
      longitude: 120,
      station: nearby,
    );

    expect(distance, greaterThan(40));
    expect(distance, lessThan(70));
    expect(formatDistance(distance), '56 m away');
  });

  test('sorts nearest first and preserves source order without a location', () {
    expect(
      sortStationsByDistance(
        stations: [far, nearby],
        latitude: 15,
        longitude: 120,
      ).map((station) => station.id),
      ['nearby', 'far'],
    );
    expect(
      sortStationsByDistance(
        stations: [far, nearby],
        latitude: null,
        longitude: null,
      ).map((station) => station.id),
      ['far', 'nearby'],
    );
  });
}
