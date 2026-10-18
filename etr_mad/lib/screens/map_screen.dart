import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/station_repository.dart';
import '../models/station.dart';
import '../presentation/station_filters.dart';
import '../presentation/station_distance.dart';
import '../presentation/station_actions.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.repository});

  final StationRepository repository;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultCenter = LatLng(15.9885, 120.5736);
  final _mapController = MapController();
  final _searchController = TextEditingController();
  List<Station> _stations = const [];
  StationStatusFilter _statusFilter = StationStatusFilter.all;
  bool _loading = true;
  bool _locating = false;
  String? _errorMessage;
  String? _selectedStationId;
  double? _userLatitude;
  double? _userLongitude;

  List<Station> get _filteredStations => sortStationsByDistance(
        stations: filterStations(
          stations: _stations,
          query: _searchController.text,
          status: _statusFilter,
        ),
        latitude: _userLatitude,
        longitude: _userLongitude,
      );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
    _loadStations();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onFilterChanged)
      ..dispose();
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  Future<void> _loadStations() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final stations = await widget.repository.loadStations();
      if (!mounted) return;
      setState(() {
        _stations = stations;
        _loading = false;
      });
      await _loadAvailableLocation();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Stations could not be loaded. Please try again.';
      });
      debugPrint('Station loading failed: $error');
    }
  }

  Future<void> _loadAvailableLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLatitude = position.latitude;
        _userLongitude = position.longitude;
      });
    } catch (error) {
      debugPrint('Current location unavailable: $error');
    }
  }

  Future<void> _showCurrentLocation() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
      }
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location is unavailable. You can still browse the station map.',
          ),
        ),
      );
      debugPrint('Location unavailable: $error');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _statusFilter = StationStatusFilter.all);
  }

  void _showStationDetails(Station station) {
    setState(() => _selectedStationId = station.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 560),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (station.photoUrl case final photoUrl?) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    ),
                  ),
                  if (station.photoAttribution case final attribution?) ...[
                    const SizedBox(height: 6),
                    Text(
                      attribution,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ] else ...[
                  _photoPlaceholder(),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (station.category case final category?) ...[
                  _infoRow(Icons.category_outlined, _categoryLabel(category)),
                  const SizedBox(height: 8),
                ],
                if (_distanceFor(station) case final distance?) ...[
                  _infoRow(Icons.near_me_outlined, formatDistance(distance)),
                  const SizedBox(height: 8),
                ],
                if (station.address case final address?) ...[
                  _infoRow(Icons.place_outlined, address),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: _statusChip(station.isOpen),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.verified_outlined,
                  _verificationLabel(station),
                ),
                const SizedBox(height: 8),
                if (station.hours case final hours?) ...[
                  _infoRow(Icons.access_time, hours),
                  const SizedBox(height: 8),
                ],
                if (station.contact case final contact?)
                  _infoRow(Icons.phone, contact),
                if (station.source case final source?) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.source_outlined,
                    station.lastVerified == null
                        ? 'Source: $source'
                        : 'Source: $source · Verified ${_dateLabel(station.lastVerified!)}',
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: directionsUri(station) == null
                          ? null
                          : () => _openExternal(
                                directionsUri(station)!,
                                'Directions could not be opened.',
                              ),
                      icon: const Icon(Icons.directions_outlined),
                      label: const Text('Directions'),
                    ),
                    if (hasValidContact(station.contact))
                      OutlinedButton.icon(
                        onPressed: () => _openExternal(
                          Uri(scheme: 'tel', path: station.contact!.trim()),
                          'Calling is unavailable on this device.',
                        ),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  color: AppColors.background,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Station details and status reports are read-only for now. '
                      'Reports will be enabled after a secure backend and admin '
                      'approval workflow are available.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop_outlined, size: 42, color: AppColors.forest),
          SizedBox(height: 8),
          Text('No sourced photo available'),
        ],
      ),
    );
  }

  Widget _statusChip(bool? isOpen) {
    final color = _statusColor(isOpen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(isOpen),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _statusColor(bool? isOpen) {
    if (isOpen == true) return AppColors.open;
    if (isOpen == false) return AppColors.closed;
    return AppColors.sage;
  }

  String _statusLabel(bool? isOpen) {
    if (isOpen == true) return 'OPEN';
    if (isOpen == false) return 'CLOSED';
    return 'UNVERIFIED';
  }

  double? _distanceFor(Station station) {
    if (_userLatitude == null || _userLongitude == null) return null;
    return distanceInMeters(
      latitude: _userLatitude!,
      longitude: _userLongitude!,
      station: station,
    );
  }

  String _verificationLabel(Station station) {
    final status = switch (station.verificationStatus) {
      VerificationStatus.verified => 'Verified',
      VerificationStatus.manuallyVerified => 'Manually verified',
      VerificationStatus.unverified => 'Unverified',
    };
    if (station.lastVerified case final date? when _isStale(date)) {
      return '$status · stale since ${_dateLabel(date)}';
    }
    return station.lastVerified == null
        ? status
        : '$status · checked ${_dateLabel(station.lastVerified!)}';
  }

  bool _isStale(DateTime date) => DateTime.now().difference(date).inDays > 365;

  String _dateLabel(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _openExternal(Uri uri, String failureMessage) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage)));
      }
    } catch (error) {
      debugPrint('External action failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failureMessage)));
      }
    }
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'water_refilling_shop' => 'Water-refilling shop',
      'public_drinking_water' => 'Public drinking water',
      'public_water_point' => 'Public water point',
      'water_refilling_station' => 'Water-refilling station',
      _ => category,
    };
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(color: Colors.grey[800])),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Explore stations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStations,
            tooltip: 'Refresh stations',
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wideLayout = constraints.maxWidth >= 800;
            final map = _buildMap();
            final list = _buildStationList();
            return Column(
              children: [
                _buildSearchControls(),
                Expanded(
                  child: wideLayout
                      ? Row(
                          children: [
                            Expanded(child: map),
                            SizedBox(width: 320, child: list),
                          ],
                        )
                      : Column(
                          children: [
                            Expanded(child: map),
                            SizedBox(height: 220, child: list),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _locating ? null : _showCurrentLocation,
        tooltip: 'Use my location',
        child: _locating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildSearchControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search station names',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear search',
                    ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<StationStatusFilter>(
              segments: const [
                ButtonSegment(
                  value: StationStatusFilter.all,
                  label: Text('All'),
                ),
                ButtonSegment(
                  value: StationStatusFilter.open,
                  label: Text('Open'),
                ),
                ButtonSegment(
                  value: StationStatusFilter.closed,
                  label: Text('Closed'),
                ),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (selection) {
                setState(() => _statusFilter = selection.first);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _defaultCenter,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hanaptubig.etr_mad',
            ),
            MarkerLayer(
              markers: _filteredStations
                  .map(
                    (station) => Marker(
                      point: LatLng(station.latitude, station.longitude),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _showStationDetails(station),
                        child: Icon(
                          Icons.location_on,
                          size: 44,
                          color: station.id == _selectedStationId
                              ? AppColors.forest
                              : _statusColor(station.isOpen),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  'OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
        if (_loading) _statusOverlay(const CircularProgressIndicator()),
        if (_errorMessage != null)
          _statusOverlay(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 44),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadStations,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (!_loading && _errorMessage == null && _stations.isEmpty)
          _emptyDatasetNotice(),
        if (!_loading &&
            _errorMessage == null &&
            _stations.isNotEmpty &&
            _filteredStations.isEmpty)
          _noMatchesNotice(),
      ],
    );
  }

  Widget _buildStationList() {
    final stations = _filteredStations;
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? const Center(child: Text('Station list unavailable.'))
              : stations.isEmpty
                  ? const Center(child: Text('No matching stations.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(8),
                      itemCount: stations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        return ListTile(
                          onTap: () => _showStationDetails(station),
                          leading: Icon(
                            Icons.location_on,
                            color: station.id == _selectedStationId
                                ? AppColors.forest
                                : _statusColor(station.isOpen),
                          ),
                          title: Text(station.name),
                          subtitle: Text(
                            [
                              _statusLabel(station.isOpen),
                              if (_distanceFor(station) case final distance?)
                                formatDistance(distance),
                            ].join(' · '),
                            style: TextStyle(
                              color: _statusColor(station.isOpen),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        );
                      },
                    ),
    );
  }

  Widget _statusOverlay(Widget child) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.12),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }

  Widget _emptyDatasetNotice() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Card(
        color: Colors.white.withValues(alpha: 0.94),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'No station dataset is configured yet. The map is available; '
            'add an authorized dataset or enable Firebase reads to show '
            'station markers.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _noMatchesNotice() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: Card(
        color: Colors.white.withValues(alpha: 0.94),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'No stations match the current search and status filter.',
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
