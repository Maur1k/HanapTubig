import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'edit_station_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final LatLng center = const LatLng(15.9885, 120.5736);
  Set<Marker> markers = {};
  bool loading = false;
  bool locationPermissionGranted = false;
  String? errorMessage;

  // Add new variables for station data
  Map<String, dynamic> selectedStation = {};
  bool isStationOpen = true;

  @override
  void initState() {
    super.initState();
    checkPermissionAndLoad();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> checkPermissionAndLoad() async {
    try {
      bool granted = await handleLocationPermission();
      if (granted) {
        setState(() {
          locationPermissionGranted = true;
          errorMessage = null;
        });
        await loadStations();
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error initializing map: $e';
      });
    }
  }

  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          errorMessage =
              'Location services are disabled. Please enable them in your device settings.';
        });
        return false;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            errorMessage =
                'Location permissions are denied. Please enable them to use the map.';
          });
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          errorMessage =
              'Location permissions are permanently denied. Please enable them in your device settings.';
        });
        return false;
      }

      return true;
    } catch (e) {
      setState(() {
        errorMessage = 'Error checking location permission: $e';
      });
      return false;
    }
  }

  void onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    if (!locationPermissionGranted) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          16.0,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> loadStations() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('refill_stations').get();

      if (!mounted) return;

      final newMarkers = snapshot.docs.map((doc) {
        var data = doc.data();
        return Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(
            data['latitude'] as double,
            data['longitude'] as double,
          ),
          onTap: () => _showStationDetails(doc.id, data),
        );
      }).toSet();

      setState(() {
        markers = newMarkers;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Error loading water stations: $e';
      });
    }
  }

  void _showStationDetails(String stationId, Map<String, dynamic> stationData) {
    setState(() {
      selectedStation = {...stationData, 'id': stationId};
      isStationOpen = stationData['isOpen'] ?? true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Station Details
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            stationData['name'] ?? 'Water Station',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isStationOpen
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isStationOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              color: isStationOpen
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.access_time,
                        'Hours: ${stationData['hours'] ?? 'Not specified'}'),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.phone,
                        'Contact: ${stationData['contact'] ?? 'Not specified'}'),
                    SizedBox(height: 24),
                    Text(
                      'Status Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStationStatus(
                                stationId, true, setModalState),
                            icon: Icon(Icons.check_circle_outline,
                                color: Colors.white),
                            label: Text(
                              'Mark as Open',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isStationOpen
                                  ? Colors.green
                                  : Colors.grey[300],
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateStationStatus(
                                stationId, false, setModalState),
                            icon: Icon(Icons.cancel_outlined,
                                color: Colors.white),
                            label: Text(
                              'Mark as Closed',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isStationOpen
                                  ? Colors.red
                                  : Colors.grey[300],
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _editStationDetails(stationId, stationData),
                      icon: Icon(Icons.edit, color: Colors.white),
                      label: Text(
                        'Edit Station Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: EdgeInsets.symmetric(vertical: 12),
                        minimumSize: Size(double.infinity, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStationStatus(
      String stationId, bool isOpen, StateSetter setModalState) async {
    try {
      await FirebaseFirestore.instance
          .collection('refill_stations')
          .doc(stationId)
          .update({'isOpen': isOpen});

      setModalState(() {
        isStationOpen = isOpen;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Station status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update station status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editStationDetails(
      String stationId, Map<String, dynamic> stationData) async {
    Navigator.pop(context); // Close the bottom sheet
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStationScreen(
          stationId: stationId,
          stationData: stationData,
        ),
      ),
    );

    if (result == true) {
      // Refresh the stations if edit was successful
      loadStations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Container(
          margin: EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, color: Colors.blue[700]),
            SizedBox(width: 8),
            Text(
              'HanapTubig',
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue[700]),
              onPressed: loadStations,
              tooltip: 'Refresh Stations',
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: center,
              zoom: 14.0,
            ),
            markers: markers,
            myLocationEnabled: locationPermissionGranted,
            myLocationButtonEnabled: locationPermissionGranted,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (loading)
            Container(
              color: Colors.black12,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading Stations...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (errorMessage != null)
            Container(
              color: Colors.black12,
              padding: EdgeInsets.all(16),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: 48,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => errorMessage = null);
                            checkPermissionAndLoad();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: locationPermissionGranted
          ? Container(
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.my_location, color: Colors.blue[700]),
                onPressed: () async {
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.high,
                    );
                    mapController.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(position.latitude, position.longitude),
                        16.0,
                      ),
                    );
                  } catch (e) {
                    print('Error getting location: $e');
                  }
                },
                tooltip: 'My Location',
              ),
            )
          : null,
    );
  }
}
