import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etr_mad/data/station_repository.dart';
import 'package:etr_mad/main.dart';
import 'package:etr_mad/models/station.dart';
import 'package:etr_mad/presentation/station_filters.dart';
import 'package:etr_mad/screens/home_screen.dart';

class _FakeStationRepository implements StationRepository {
  const _FakeStationRepository(this.stations);

  final List<Station> stations;

  @override
  Future<List<Station>> loadStations() async => stations;
}

const _testStations = [
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
];

void main() {
  testWidgets('local mode navigates to an empty map', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const HanapTubigApp(repository: _FakeStationRepository([])),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.text('Explore stations'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.textContaining('No station dataset is configured yet'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.location_on), findsNothing);
  });

  testWidgets('map list and markers use the same filtered stations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const HanapTubigApp(
        repository: _FakeStationRepository(_testStations),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore stations'));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Purifa Water Refilling Station'), findsOneWidget);
    expect(find.text('Clear Water'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsNWidgets(2));

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<StationStatusFilter>),
        matching: find.text('Open'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Purifa Water Refilling Station'), findsOneWidget);
    expect(find.text('Clear Water'), findsNothing);
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      '  purifa  ',
    );
    await tester.pump();
    expect(find.text('Purifa Water Refilling Station'), findsOneWidget);
    expect(find.text('Clear Water'), findsNothing);
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();
    expect(find.text('Purifa Water Refilling Station'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<StationStatusFilter>),
        matching: find.text('All'),
      ),
    );
    await tester.pump();
    expect(find.text('Clear Water'), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsNWidgets(2));
  });

  testWidgets('no-match search keeps the map visible and offers clear', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const HanapTubigApp(
        repository: _FakeStationRepository(_testStations),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore stations'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pump();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(
      find.text('No stations match the current search and status filter.'),
      findsOneWidget,
    );
    expect(find.text('Clear'), findsOneWidget);
  });
}
