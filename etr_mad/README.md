# HanapTubig Flutter app

Run from this directory:

```bash
flutter pub get
flutter run
```

The default local/demo mode does not initialize Firebase and loads the
reviewed Urdaneta City OSM-derived dataset. Firebase reads are explicitly
opt-in:

```bash
flutter run --dart-define=HANAPTUBIG_DATA_SOURCE=firebase
```

The map uses OpenStreetMap tiles through `flutter_map`, with visible
OpenStreetMap attribution. Follow the
[OpenStreetMap tile policy](https://operations.osmfoundation.org/policies/tiles/).

Station details are read-only. Direct edits and open/closed writes are
disabled; future reports require a separate pending-report backend and
authenticated, server-enforced administrator approval.

The map screen supports trimmed, case-insensitive station-name search and
All/Open/Closed status filters. The station list and map markers always use the
same filtered station collection. When location is available, both are ordered
nearest-first and show a distance; browsing remains available without location.
Directions use a coordinate-based external Google Maps URL, while calls are
shown only for sourced phone numbers.

The checked-in dataset contains six named `water_refilling_shop` records from
the Urdaneta administrative boundary. It currently contains no public-water
records, photos, addresses, phone numbers, opening hours, or verified records.
Use the repository's versioned Overpass query and importer to refresh it; see
the root README. Imported records are unverified unless manually checked, and
missing operating status is never assumed to be open. Photos are shown only
when the source explicitly provides an `image` or `wikimedia_commons` tag.

For dataset import guidance, static web deployment, and validation commands,
see the repository [README](../README.md).
