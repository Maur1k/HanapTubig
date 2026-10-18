import '../models/station.dart';

Uri? directionsUri(Station station) {
  return Uri.https(
    'www.google.com',
    '/maps/dir/',
    {'api': '1', 'destination': '${station.latitude},${station.longitude}'},
  );
}

bool hasValidContact(String? contact) =>
    contact != null && contact.trim().isNotEmpty;
