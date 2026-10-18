"""Normalize an Overpass JSON export into HanapTubig station records.

This script never invents names or coordinates. It skips OSM elements without
both a name and usable coordinates. Run it with an Overpass JSON response:

    python tools/import_osm_stations.py \
        --input overpass-philippines.json \
        --output etr_mad/assets/data/stations.json

The output is safe to review and commit as an authorized local dataset. OSM
records remain unverified until a human verifies them. Existing records marked
``manually_verified`` retain their manually managed fields during refreshes.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def coordinates(element: dict[str, Any]) -> tuple[float, float] | None:
    lat = element.get("lat")
    lon = element.get("lon")
    center = element.get("center")
    if isinstance(center, dict):
        lat = center.get("lat", lat)
        lon = center.get("lon", lon)
    if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
        return None
    if not -90 <= lat <= 90 or not -180 <= lon <= 180:
        return None
    return float(lat), float(lon)


def category(tags: dict[str, Any]) -> str:
    if tags.get("water_refilling_station") == "yes":
        return "water_refilling_station"
    if tags.get("shop") == "water":
        return "water_refilling_shop"
    if tags.get("amenity") in {"drinking_water", "water_point"}:
        return f"public_{tags['amenity']}"
    return "water_station"


def image_url(tags: dict[str, Any]) -> tuple[str, str] | None:
    image = tags.get("image")
    if isinstance(image, str) and image.startswith(("https://", "http://")):
        return image, "OpenStreetMap image tag"
    commons = tags.get("wikimedia_commons")
    if isinstance(commons, str) and commons.startswith("File:"):
        return (
            "https://commons.wikimedia.org/wiki/Special:FilePath/"
            + commons[5:].strip().replace(" ", "_"),
            "Wikimedia Commons via OpenStreetMap",
        )
    return None


def verification_date(tags: dict[str, Any]) -> str | None:
    for key in ("survey:date", "check_date", "lastcheck"):
        value = tags.get(key)
        if isinstance(value, str):
            try:
                return datetime.fromisoformat(value).date().isoformat()
            except ValueError:
                continue
    return None


def normalize(element: dict[str, Any]) -> dict[str, Any] | None:
    tags = element.get("tags")
    point = coordinates(element)
    if not isinstance(tags, dict) or point is None:
        return None
    name = tags.get("name")
    if not isinstance(name, str) or not name.strip():
        return None
    element_type = element.get("type")
    osm_id = element.get("id")
    if not isinstance(element_type, str) or not isinstance(osm_id, int):
        return None

    record: dict[str, Any] = {
        "id": f"osm:{element_type}/{osm_id}",
        "name": name.strip(),
        "latitude": point[0],
        "longitude": point[1],
        "source": "OpenStreetMap",
        "sourceId": f"{element_type}/{osm_id}",
        "category": category(tags),
        "verificationStatus": "unverified",
    }
    hours = tags.get("opening_hours")
    if isinstance(hours, str) and hours.strip():
        record["hours"] = hours.strip()
    address_parts = [
        tags.get(key)
        for key in ("addr:housenumber", "addr:street", "addr:place", "addr:city")
        if isinstance(tags.get(key), str) and tags[key].strip()
    ]
    if address_parts:
        record["address"] = ", ".join(part.strip() for part in address_parts)
    contact = tags.get("phone") or tags.get("contact:phone")
    if isinstance(contact, str) and contact.strip():
        record["contact"] = contact.strip()
    verified = verification_date(tags)
    if verified is not None:
        record["lastVerified"] = verified
    photo = image_url(tags)
    if photo is not None:
        record["photoUrl"], record["photoAttribution"] = photo
    return record


def merge(existing: list[dict[str, Any]], imported: list[dict[str, Any]]) -> list[dict[str, Any]]:
    by_source_id = {
        record.get("sourceId"): record
        for record in existing
        if isinstance(record, dict) and record.get("sourceId")
    }
    for record in imported:
        source_id = record["sourceId"]
        previous = by_source_id.get(source_id)
        if isinstance(previous, dict) and previous.get("verificationStatus") == "manually_verified":
            merged = dict(record)
            for field in (
                "name", "latitude", "longitude", "hours", "contact", "category",
                "address",
                "photoUrl", "photoAttribution",
            ):
                if field in previous:
                    merged[field] = previous[field]
            merged["verificationStatus"] = "manually_verified"
            merged["lastVerified"] = previous.get("lastVerified")
            by_source_id[source_id] = merged
        else:
            by_source_id[source_id] = record
    return sorted(by_source_id.values(), key=lambda record: record["id"])


def main() -> None:
    args = parse_args()
    payload = json.loads(args.input.read_text(encoding="utf-8"))
    elements = payload.get("elements") if isinstance(payload, dict) else None
    if not isinstance(elements, list):
        raise SystemExit("Input must be an Overpass JSON object with an elements array.")
    imported = [
        record
        for element in elements
        if isinstance(element, dict)
        for record in [normalize(element)]
        if record is not None
    ]
    imported_by_id = {record["sourceId"]: record for record in imported}
    duplicates_skipped = len(imported) - len(imported_by_id)
    invalid_skipped = len(elements) - len(imported)
    category_counts = Counter(
        record["category"] for record in imported_by_id.values()
    )
    existing = []
    if args.output.exists():
        data = json.loads(args.output.read_text(encoding="utf-8"))
        if isinstance(data, list):
            existing = [record for record in data if isinstance(record, dict)]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(merge(existing, imported), indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(
        f"Imported {len(imported_by_id)} OSM records; "
        f"categories {dict(category_counts)}; "
        f"skipped {duplicates_skipped} duplicate source IDs and "
        f"{invalid_skipped} invalid records; wrote {args.output}"
    )


if __name__ == "__main__":
    main()
