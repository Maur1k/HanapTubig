# Firestore data model

## Collection: `refill_stations`

The current map screen reads all documents from `refill_stations` and uses each document ID as the station marker ID. The following fields are referenced by the current Flutter code. Confirm the live database schema before treating this as a formal contract.

| Field | Expected type | Purpose | Used by |
|---|---|---|---|
| `name` | string | Station display name | Map station details; edit form |
| `latitude` | number (stored as a Dart-compatible numeric value) | Geographic latitude | Map marker |
| `longitude` | number (stored as a Dart-compatible numeric value) | Geographic longitude | Map marker |
| `isOpen` | boolean | Reported open/closed status | Station details and status buttons |
| `hours` | string | Operating hours text | Station details; edit form |
| `contact` | string | Contact number or contact text | Station details; edit form |
| `lastUpdated` | Firestore timestamp (written by the edit form) | Time station details were last edited | Edit form write |

### Current behavior

- The app loads all documents in the collection and creates a marker for each document.
- Marker position is read from `latitude` and `longitude`.
- Tapping a marker displays the station name, hours, contact, and status.
- The status controls update `isOpen` directly.
- The edit form updates `name`, `hours`, `contact`, and `lastUpdated` directly.

### Data validation recommendations

Before production use, define required fields and validate them in Security Rules or a trusted backend:

- `name`: non-empty string with a reasonable maximum length.
- `latitude`: number in the range -90 through 90.
- `longitude`: number in the range -180 through 180.
- `isOpen`: boolean.
- `hours` and `contact`: strings with appropriate length limits.
- `lastUpdated`: server timestamp written only by an authorized update path.

Avoid allowing clients to add arbitrary fields. Ensure the rules validate the exact keys and field types, and restrict which fields each role may change.

## Important caveat

This schema is inferred from the checked-in Flutter code, not exported from the live Firestore database. Verify actual documents, optional fields, and existing data before deploying rules or running migrations.
