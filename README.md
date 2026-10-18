# HanapTubig

HanapTubig is a Flutter mobile application concept that helps people find water-refilling stations on a map. It combines Google Maps, device location, and Firebase Cloud Firestore to display station locations and basic station details.

> **Project status:** Academic project being prepared for a stronger portfolio release. Firebase configuration and the existing Flutter code have been reviewed, but production security rules, full platform testing, and screenshots still need to be completed.

## The problem

Finding a nearby water-refilling station can be inconvenient when station locations and operating details are scattered or difficult to verify. HanapTubig brings station locations and key information into one map-based experience.

## Current user flow

1. Launch HanapTubig and view its splash screen.
2. Open the home screen and choose **Maghanap ng Tubigan**.
3. Grant location permission so the map can center on the user's current location.
4. View water-refilling station markers and tap a marker to see its name, operating hours, contact details, and open/closed status.
5. The current prototype also includes controls to report a station's status and edit station details. These write actions are not yet protected by a verified role-based authorization system and should not be treated as production-ready.

## Technology stack

- **Flutter / Dart** — cross-platform UI
- **Firebase Core** — Firebase initialization
- **Cloud Firestore** — station records
- **Google Maps for Flutter** — map and station markers
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
- A Firebase project with Cloud Firestore configured
- A Google Maps API key enabled for the target platform

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

4. Verify Firebase configuration for your own Firebase project. See [Firebase setup](docs/FIREBASE_SETUP.md). Do not copy private credentials from another project.
5. Configure Google Maps for your target platform using the official [Google Maps for Flutter setup guide](https://pub.dev/packages/google_maps_flutter).
6. Run on a configured device or emulator:

   ```bash
   flutter run
   ```

## Firebase and data model

The app currently reads station documents from the `refill_stations` collection. The observed fields and expected types are documented in [Firestore data model](docs/FIRESTORE_DATA_MODEL.md).

Firebase project configuration is present in `etr_mad/lib/firebase_options.dart`, `etr_mad/firebase.json`, and the Android Google Services configuration. These files identify client apps and are not a substitute for access control. Review and configure API-key restrictions and Firestore Security Rules for your own deployment.

**Security warning:** the current app code contains direct Firestore updates for station status and station details, and this repository does not currently contain a `firestore.rules` file. Do not assume writes are restricted. Before using real data, define who may edit stations, implement and deploy restrictive Firestore Security Rules, and test the rules with the Firebase Emulator Suite. See the security checklist in [Firebase setup](docs/FIREBASE_SETUP.md).

## Supported platforms

- **Android:** Firebase options and Android app configuration are present; build/run testing is still required.
- **Web:** Firebase web options are present, but Google Maps configuration and end-to-end behavior must be verified.
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
