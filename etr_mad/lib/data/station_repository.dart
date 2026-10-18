import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/station.dart';

abstract interface class StationRepository {
  Future<List<Station>> loadStations();
}

class LocalStationRepository implements StationRepository {
  const LocalStationRepository({this.assetPath = 'assets/data/stations.json'});

  final String assetPath;

  @override
  Future<List<Station>> loadStations() async {
    final encoded = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      throw const FormatException('Station dataset must be a JSON array.');
    }

    final stations = <Station>[];
    for (final value in decoded) {
      if (value is! Map) continue;
      final data = Map<String, dynamic>.from(value);
      final id = data['id'] as String?;
      if (id == null || id.isEmpty) continue;
      try {
        stations.add(Station.fromMap(id, data));
      } on FormatException {
        // Skip malformed imported records without hiding valid stations.
      }
    }
    return stations;
  }
}

class FirebaseStationRepository implements StationRepository {
  FirebaseStationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Station>> loadStations() async {
    final snapshot = await _firestore.collection('refill_stations').get();
    final stations = <Station>[];
    for (final document in snapshot.docs) {
      try {
        stations.add(Station.fromMap(document.id, document.data()));
      } on FormatException {
        // Ignore malformed records so valid stations remain visible.
      }
    }
    return stations;
  }
}
