# Firestore data model

## Collection: `refill_stations`

The optional Firebase repository reads documents from `refill_stations` and
uses each document ID as the station marker ID. The following fields are
referenced by the Flutter code. Confirm the live database schema before
treating this as a formal contract.

| Field | Expected type | Purpose | Used by |
|---|---|---|---|
| `name` | string | Station display name | Map station details; edit form |
| `latitude` | number (stored as a Dart-compatible numeric value) | Geographic latitude | Map marker |
| `longitude` | number (stored as a Dart-compatible numeric value) | Geographic longitude | Map marker |
| `isOpen` | boolean | Reported open/closed status | Station details and status buttons |
| `hours` | string | Operating hours text | Station details; edit form |
| `contact` | string | Contact number or contact text | Station details; edit form |
| `source` | string | Human-readable source attribution | Station provenance |
| `sourceId` | string | Stable identifier from the source, such as `node/123` | Import deduplication |
| `category` | string | Source category, such as `water_point` or `shop` | Station metadata |
| `photoUrl` | string | Explicitly sourced image URL from OSM image/Common tags | Station details |
| `photoAttribution` | string | Provenance label for the photo | Station details |
| `verificationStatus` | string | `unverified`, `verified`, or `manually_verified` | Trust display and refresh merge |
| `lastUpdated` | Firestore timestamp | Time station details were last edited by a trusted workflow | Future backend |
| `lastVerified` | timestamp/string | Most recent supported verification or survey date | Trust metadata |

### Current read behavior

- Firebase mode loads all documents in the collection and creates a marker for each document.
- Local/demo mode reads the generated `etr_mad/assets/data/stations.json` dataset.
- Marker position is read from `latitude` and `longitude`.
- Tapping a marker displays a sourced photo when available, then station name,
  category, hours, contact, and status.
- The public client does not update `isOpen` or any other station field.
- Missing `isOpen` remains unverified; it is not treated as open.

## OpenStreetMap import

The repeatable import workflow is documented in the repository README and uses
the versioned [`tools/osm_overpass_query.ql`](../tools/osm_overpass_query.ql)
query plus [`tools/import_osm_stations.py`](../tools/import_osm_stations.py).
The importer accepts an Overpass JSON response, skips missing names or
coordinates, stores OSM provenance and stable source IDs, and preserves
manually verified fields during refreshes. The generated local dataset must be
reviewed before release and must not be described as nationwide-complete.

### Data validation recommendations

Before production use, define required fields and validate them in Security Rules or a trusted backend:

- `name`: non-empty string with a reasonable maximum length.
- `latitude`: number in the range -90 through 90.
- `longitude`: number in the range -180 through 180.
- `isOpen`: boolean.
- `hours` and `contact`: strings with appropriate length limits.
- `lastUpdated`: server timestamp written only by an authorized update path.

Avoid allowing clients to add arbitrary fields. Ensure the rules validate the exact keys and field types, and restrict which fields each role may change.

## Report workflow

User reports should be stored separately as pending reports, reviewed by an
authenticated administrator, and applied by a trusted backend or
server-enforced role. Never allow a public client to overwrite canonical
station records.

## Important caveat

This schema is inferred from the checked-in Flutter code, not exported from
the live Firestore database. Verify actual documents, optional fields, and
existing data before deploying rules or running migrations.
