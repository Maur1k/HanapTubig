import 'package:flutter_test/flutter_test.dart';

import 'package:etr_mad/models/station.dart';

void main() {
  test('missing status remains unverified instead of defaulting open', () {
    final station = Station.fromMap('osm:node/1', {
      'name': 'Mapped Water Point',
      'latitude': 14.6,
      'longitude': 121.0,
      'source': 'OpenStreetMap',
      'sourceId': 'node/1',
      'category': 'water_point',
    });

    expect(station.isOpen, isNull);
    expect(station.verificationStatus, VerificationStatus.unverified);
    expect(station.isVerified, isFalse);
  });

  test('invalid or missing coordinates are rejected', () {
    expect(
      () => Station.fromMap('bad', {'name': 'No coordinates'}),
      throwsFormatException,
    );
    expect(
      () => Station.fromMap('bad', {
        'name': 'Outside bounds',
        'latitude': 95,
        'longitude': 121,
      }),
      throwsFormatException,
    );
  });

  test('missing names are rejected instead of being invented', () {
    expect(
      () => Station.fromMap('unnamed', {
        'latitude': 14.6,
        'longitude': 121.0,
      }),
      throwsFormatException,
    );
  });

  test('keeps sourced address and contact fields', () {
    final station = Station.fromMap('osm:node/2', {
      'name': 'Mapped Shop',
      'latitude': 15.98,
      'longitude': 120.57,
      'address': '1 Main Street, Urdaneta City',
      'contact': '+63 900 000 0000',
    });

    expect(station.address, '1 Main Street, Urdaneta City');
    expect(station.contact, '+63 900 000 0000');
  });
}
