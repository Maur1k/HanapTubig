import unittest

from import_osm_stations import merge, normalize


class ImportOsmStationsTest(unittest.TestCase):
    def test_normalizes_named_point_and_marks_status_unverified(self):
        record = normalize({
            "type": "node",
            "id": 42,
            "lat": 14.6,
            "lon": 121.0,
            "tags": {
                "name": "Authorized Water Point",
                "amenity": "water_point",
                "opening_hours": "Mo-Fr 08:00-17:00",
            },
        })
        self.assertEqual(record["id"], "osm:node/42")
        self.assertEqual(record["sourceId"], "node/42")
        self.assertEqual(record["verificationStatus"], "unverified")
        self.assertIsNone(record.get("isOpen"))

    def test_skips_missing_coordinates_or_names(self):
        self.assertIsNone(normalize({
            "type": "node", "id": 1, "tags": {"name": "Missing point"}
        }))

    def test_keeps_water_categories_distinct_and_accepts_sourced_photo(self):
        shop = normalize({
            "type": "node", "id": 3, "lat": 15.9, "lon": 120.5,
            "tags": {
                "name": "Mapped Shop",
                "shop": "water",
                "image": "https://example.test/station.jpg",
                "phone": "+63 900 000 0000",
                "addr:street": "Main Street",
                "addr:city": "Urdaneta City",
            },
        })
        public = normalize({
            "type": "node", "id": 4, "lat": 15.9, "lon": 120.5,
            "tags": {"name": "Public Point", "amenity": "water_point"},
        })
        self.assertEqual(shop["category"], "water_refilling_shop")
        self.assertEqual(shop["photoUrl"], "https://example.test/station.jpg")
        self.assertEqual(shop["contact"], "+63 900 000 0000")
        self.assertEqual(shop["address"], "Main Street, Urdaneta City")
        self.assertEqual(public["category"], "public_water_point")
        self.assertIsNone(normalize({
            "type": "node", "id": 2, "lat": 14.6, "lon": 121.0, "tags": {}
        }))

    def test_deduplicates_by_source_id_and_preserves_manual_fields(self):
        existing = [{
            "id": "osm:node/42",
            "sourceId": "node/42",
            "name": "Manually Verified Name",
            "latitude": 14.7,
            "longitude": 121.1,
            "contact": "authorized-contact",
            "verificationStatus": "manually_verified",
            "lastVerified": "2026-01-01",
        }]
        imported = [{
            "id": "osm:node/42",
            "sourceId": "node/42",
            "name": "Less Reliable OSM Name",
            "latitude": 14.6,
            "longitude": 121.0,
            "verificationStatus": "unverified",
        }]
        merged = merge(existing, imported)
        self.assertEqual(len(merged), 1)
        self.assertEqual(merged[0]["name"], "Manually Verified Name")
        self.assertEqual(merged[0]["contact"], "authorized-contact")
        self.assertEqual(merged[0]["latitude"], 14.7)


if __name__ == "__main__":
    unittest.main()
