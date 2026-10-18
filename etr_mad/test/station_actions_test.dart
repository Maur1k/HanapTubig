import 'package:flutter_test/flutter_test.dart';

import 'package:etr_mad/models/station.dart';
import 'package:etr_mad/presentation/station_actions.dart';

void main() {
  test('directions use the station coordinates', () {
    const station = Station(
      id: 'one',
      name: 'One',
      latitude: 15.98,
      longitude: 120.57,
    );

    expect(
      directionsUri(station).toString(),
      'https://www.google.com/maps/dir/?api=1&destination=15.98%2C120.57',
    );
  });

  test('call action is available only for a non-empty contact', () {
    expect(hasValidContact(null), isFalse);
    expect(hasValidContact('  '), isFalse);
    expect(hasValidContact('+63 900 000 0000'), isTrue);
  });
}
