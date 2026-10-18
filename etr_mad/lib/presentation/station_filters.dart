import '../models/station.dart';

enum StationStatusFilter { all, open, closed }

List<Station> filterStations({
  required Iterable<Station> stations,
  required String query,
  required StationStatusFilter status,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return stations.where((station) {
    final matchesQuery = normalizedQuery.isEmpty ||
        station.name.toLowerCase().contains(normalizedQuery);
    final matchesStatus = switch (status) {
      StationStatusFilter.all => true,
      StationStatusFilter.open => station.isOpen == true,
      StationStatusFilter.closed => station.isOpen == false,
    };
    return matchesQuery && matchesStatus;
  }).toList(growable: false);
}
