# Firebase setup and security checklist

This document describes the Firebase setup visible in the repository and the steps needed before treating HanapTubig as production-ready.

## Current configuration

The Flutter app initializes Firebase using `etr_mad/lib/firebase_options.dart`. The repository also contains `etr_mad/firebase.json` and Android's `etr_mad/android/app/google-services.json`. The configured Firebase project ID in these files is `fernandez-firestore-2025`.

Client configuration values identify Firebase applications; they do not authorize access to Firestore. Access must be controlled by Firestore Security Rules and, where required, Firebase Authentication.

## Local setup

1. Create or select a Firebase project that you control.
2. Register the app's intended platforms in Firebase.
3. From the `etr_mad/` directory, configure FlutterFire for your project with the FlutterFire CLI.
4. Ensure the generated `firebase_options.dart`, `firebase.json`, and Android configuration correspond to the intended Firebase project and Android package name.
5. Enable Cloud Firestore and create the expected station documents.
6. Configure Google Maps API keys separately for each target platform. Restrict keys by application and API where supported.
7. Run `flutter pub get`, then build and test on each platform you intend to claim as supported.

Do not commit service-account private keys, admin SDK credentials, passwords, or local secret files. If you switch Firebase projects, review all client configuration files together rather than changing only one.

## Current authorization gap

The current Flutter code performs direct updates to `refill_stations/{stationId}` for both `isOpen` status and station details. The map screen exposes these controls in the user interface. The repository did not contain a `firestore.rules` file when reviewed, and the app does not currently integrate Firebase Authentication.

This means the code alone does not establish an administrator role. Hiding buttons in Flutter is not authorization. Do not deploy permissive rules or assume public writes are safe.

## Recommended policy decision

For the public app:

- Allow unauthenticated users to read only the station fields required to display the map, if public reads are intended.
- Deny public create, update, and delete operations.
- Decide how station managers will authenticate before enabling editing.
- If only trusted administrators may edit, use Firebase Authentication plus an enforceable role/claim or a separate trusted backend. Do not rely on a client-supplied `isAdmin` field.
- Validate field names, types, allowed changes, and required values in Firestore Security Rules.
- If users should submit open/closed reports, store reports separately from the canonical station status. Add a moderation or trusted update flow rather than allowing arbitrary clients to overwrite station data.

## Before deploying rules

1. Inspect the live Firestore data and confirm the complete field schema.
2. Decide whether public reads should include all station fields or a public-safe subset.
3. Implement rules in a reviewed `firestore.rules` file.
4. Configure the Firebase Emulator Suite and write tests for allowed reads, denied writes, authorized edits, malformed fields, and unauthenticated requests.
5. Test the app against the rules in a non-production Firebase project.
6. Deploy rules to the intended Firebase project only after reviewing the target project and test results.

Do not run destructive seed/reset scripts against a live Firebase project. Back up important data before any migration.
