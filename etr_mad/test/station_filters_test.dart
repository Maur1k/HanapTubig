import 'package:flutter_test/flutter_test.dart';

import 'package:etr_mad/models/station.dart';
import 'package:etr_mad/presentation/station_filters.dart';

const stations = [
  Station(
    id: 'open-purifa',
    name: 'Purifa Water Refilling Station',
    latitude: 15,
    longitude: 120,
    isOpen: true,
  ),
  Station(
    id: 'closed-clear',
    name: 'Clear Water',
    latitude: 16,
    longitude: 121,
    isOpen: false,
  ),
  Station(
    id: 'open-spring',
    name: 'Spring Source',
    latitude: 17,
    longitude: 122,
    isOpen: true,
  ),
];

void main() {
  test('search is case-insensitive and trims whitespace', () {
    expect(
      filterStations(
        stations: stations,
        query: '  PURIFA  ',
        status: StationStatusFilter.all,
      ).map((station) => station.id),
      ['open-purifa'],
    );
  });

  test('all, open, and closed filters return the expected stations', () {
    expect(
      filterStations(
        stations: stations,
        query: '',
        status: StationStatusFilter.all,
      ),
      stations,
    );
    expect(
      filterStations(
        stations: stations,
        query: '',
        status: StationStatusFilter.open,
      ).map((station) => station.id),
      ['open-purifa', 'open-spring'],
    );
    expect(
      filterStations(
        stations: stations,
        query: '',
        status: StationStatusFilter.closed,
      ).map((station) => station.id),
      ['closed-clear'],
    );
  });

  test('search and status filters combine, and empty queries restore all', () {
    expect(
      filterStations(
        stations: stations,
        query: 'water',
        status: StationStatusFilter.open,
      ).map((station) => station.id),
      ['open-purifa'],
    );
    expect(
      filterStations(
        stations: stations,
        query: '',
        status: StationStatusFilter.all,
      ),
      stations,
    );
    expect(
      filterStations(
        stations: stations,
        query: 'unknown',
        status: StationStatusFilter.all,
      ),
      isEmpty,
    );
  });

  test('empty station collections remain empty', () {
    expect(
      filterStations(
        stations: const [],
        query: '',
        status: StationStatusFilter.all,
      ),
      isEmpty,
    );
  });
}
