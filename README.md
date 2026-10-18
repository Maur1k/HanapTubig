# HanapTubig

HanapTubig is a Flutter application concept that helps people find water-refilling stations on an OpenStreetMap-based map. It can run in local/demo mode without Firebase access and can optionally read authorized station records from Cloud Firestore.

> **Project status:** Academic project being prepared for a stronger portfolio release. Firebase configuration and the existing Flutter code have been reviewed, but production security rules, full platform testing, and screenshots still need to be completed.

## The problem

Finding a nearby water-refilling station can be inconvenient when station locations and operating details are scattered or difficult to verify. HanapTubig brings station locations and key information into one map-based experience.

## Current user flow

1. Launch HanapTubig and view its splash screen.
2. Open the home screen and choose **Maghanap ng Tubigan**.
3. Optionally grant location permission so the map can center on the user's current location. Browsing the map does not require location access.
4. Search station names, filter by All/Open/Closed, and use the synchronized station list or map markers to open a station.
5. View a station's operating hours, contact details, and open/closed status. Station details are currently read-only.
6. Reports and edits are intentionally unavailable until a secure backend and administrator approval workflow exist.

## Technology stack

- **Flutter / Dart** — cross-platform UI
- **Firebase Core / Cloud Firestore** — optional station reads
- **flutter_map / OpenStreetMap** — map and station markers
- **Geolocator** — device location and permission handling

## Repository structure

```text
HanapTubig/
├── README.md
├── docs/
│   ├── FIREBASE_SETUP.md
│   └── FIRESTORE_DATA_MODEL.md
└── etr_mad/                 # Flutter application
    ├── lib/
    │   ├── main.dart
    │   └── screens/
    ├── assets/
    ├── android/
    ├── ios/
    ├── firebase.json
    └── pubspec.yaml
```

## Run locally

### Prerequisites

- Flutter SDK compatible with the Dart SDK constraint in `etr_mad/pubspec.yaml`
- Android Studio or another supported Flutter development environment
- An authorized station dataset, if Firebase mode is used

### Setup

1. Clone this repository.
2. Open a terminal in the Flutter project directory:

   ```bash
   cd etr_mad
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run in local/demo mode (the default):

   ```bash
   flutter run
   ```

   Local mode loads the reviewed Urdaneta City OSM-derived sample dataset in
   `etr_mad/assets/data/stations.json`.
5. To opt into Firestore reads for a configured platform, run:

   ```bash
   flutter run --dart-define=HANAPTUBIG_DATA_SOURCE=firebase
   ```

   Firebase initialization failures fall back to local mode. Do not add service-account credentials or other secrets to source control.

### Station data

No station names, coordinates, addresses, or operating statuses are invented by
the app. Local mode reads `etr_mad/assets/data/stations.json`. The current
dataset contains 6 named OSM records within the Urdaneta administrative
boundary (OSM relation 19056575): 6 `water_refilling_shop` records, 0 public
drinking-water records, and 0 duplicate source IDs in this export. Records
remain unverified. To refresh or create another OSM-derived dataset:

1. Review [`tools/osm_overpass_query.ql`](tools/osm_overpass_query.ql). It
   resolves Urdaneta's actual OSM administrative area rather than using a
   guessed bounding box.
2. Run it through [Overpass Turbo](https://overpass-turbo.eu/) or an available
   Overpass endpoint and save the JSON response. For example:

   ```powershell
   Invoke-WebRequest `
     -Method Post `
     -Uri https://overpass-api.de/api/interpreter `
     -Body @{ data = Get-Content .\tools\osm_overpass_query.ql -Raw } `
     -OutFile .\overpass-philippines.json
   ```

   Respect the selected Overpass instance's capacity and usage guidance. A
   nationwide query can be large or time out; split by region if necessary.
3. Normalize and merge the export:

   ```powershell
   python .\tools\import_osm_stations.py `
     --input .\overpass-philippines.json `
     --output .\etr_mad\assets\data\stations.json
   ```

The importer uses stable `osm:{type}/{id}` and `sourceId` values, skips records
without a name or valid coordinates, records OpenStreetMap provenance and
category, imports explicitly tagged address, phone, `image`, or
`wikimedia_commons` values when present, and preserves fields on existing
`manually_verified` records during refreshes. OSM records remain `unverified`
unless a human verifies them.
Missing `isOpen` is intentionally shown as **UNVERIFIED**; OSM opening hours do
not prove that a station is currently open.

This is not a complete Urdaneta-wide or nationwide directory. Coverage depends
on what has been mapped in OpenStreetMap, local tagging practices, and the
export date. The current export had 6 imported records and no invalid or
duplicate records after normalization. Review duplicates, operating details,
photo ownership/attribution, and safety before publishing an imported dataset.
Do not scrape commercial directories or commit credentials. If Overpass times
out, retry later or split the request by smaller administrative areas; do not
hammer public endpoints.

The OpenStreetMap data import and tile layer require attribution. The tile
layer uses `https://tile.openstreetmap.org/{z}/{x}/{y}.png` with visible
**OpenStreetMap contributors** attribution. Follow the
[tile policy](https://operations.osmfoundation.org/policies/tiles/) and the
Overpass instance's limits. For production traffic, consider an appropriate
hosted tile provider or self-hosting.

### Reports and administration

The client never updates approved station records. A future implementation should use public station reads, a separate pending-reports collection or API, authenticated administrator review, and server-enforced approval before canonical station records change. Client-side buttons or claims must not be treated as authorization.

### Static web deployment

Build the web output and deploy the contents of `etr_mad/build/web` to a static host:

```bash
cd etr_mad
flutter build web
```

Configure the host to serve `index.html` for application routes. No Google Maps API key or Google Maps JavaScript API is required.

## Firebase and data model

The app currently reads station documents from the `refill_stations` collection. The observed fields and expected types are documented in [Firestore data model](docs/FIRESTORE_DATA_MODEL.md).

Firebase project configuration is present in `etr_mad/lib/firebase_options.dart`, `etr_mad/firebase.json`, and the Android Google Services configuration. These files identify client apps and are not a substitute for access control. Review and configure API-key restrictions and Firestore Security Rules for your own deployment.

**Security status:** an initial Firestore rules file now allows public reads of `refill_stations` and denies all client writes. This is intentionally read-only because the app does not yet implement Firebase Authentication or an administrator role. The rules have been committed but have **not** been deployed to Firebase. Test them with the Firebase Emulator Suite before deploying. See [Firebase setup](docs/FIREBASE_SETUP.md).

## Supported platforms

- **Android:** Firebase options and Android app configuration are present; build/run testing is still required.
- **Web:** OpenStreetMap is used without a Google Maps API key. Firebase is not initialized unless explicitly enabled.
- **iOS:** native project files exist, but the checked-in Firebase options currently do not define iOS configuration. Configure and test it before claiming support.
- **Windows, macOS, Linux:** Firebase options currently throw unsupported-platform errors; these platforms are not configured.

Platform configuration in the repository does not by itself mean the app has been tested or released on that platform.

## Screenshots

Screenshots of the splash screen, home screen, map, and station details will be added here after capturing them from a running build. No screenshots are included yet, so the README does not use mock images as evidence.

Suggested location: `docs/screenshots/`.

## Documentation

- [Firebase setup and security checklist](docs/FIREBASE_SETUP.md)
- [Firestore data model](docs/FIRESTORE_DATA_MODEL.md)

## License

No license has been specified yet. Contact the repository owner before reusing or redistributing this project.
