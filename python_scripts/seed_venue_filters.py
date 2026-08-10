"""
Seeds the Venue filter taxonomy into Supabase.

Run the DDL in supabase_migrations.sql FIRST (dashboard SQL editor or
`supabase db push`) — this script only inserts rows, it cannot create tables.

Credentials come from the environment, not from source:

    # PowerShell
    $env:SUPABASE_SERVICE_KEY = "..."
    python python_scripts/seed_venue_filters.py --inspect

    # bash
    export SUPABASE_SERVICE_KEY="..."
    python python_scripts/seed_venue_filters.py --seed

Modes:
    --inspect   Print the Venue filter groups / options that already exist.
                Read-only. Run this first — it tells you whether the new
                Venue Type list collides with your existing Setting Type,
                Catering or Venue Style options.
    --seed      Insert the new taxonomy. Idempotent: re-running is safe.

Already applied to the production project (cocmclecxanepyheygqs) on 2026-08-09
as migrations `venue_filter_schema` and `venue_filter_taxonomy_seed`. This
script is kept for re-running against a fresh or branched database.

Requires: pip install supabase
"""

import argparse
import os
import sys

from supabase import create_client, Client

URL = "https://cocmclecxanepyheygqs.supabase.co"
CATEGORY = "Venue"

VENUE_TYPE_KEY = "venue_type"
AMENITIES_KEY = "venue_amenities"
PRICE_KEY = "starting_price"
CAPACITY_KEY = "guest_capacity_range"

# ---------------------------------------------------------------- taxonomy --

# (option_value, option_label)
VENUE_TYPES = [
    ("ballroom_banquet_hall", "Ballrooms & Banquet Halls"),
    ("barn_farm_ranch", "Barns, Farms & Ranches"),
    ("beach_waterfront", "Beaches & Waterfront"),
    ("garden_arboretum", "Gardens & Arboretums"),
    ("golf_country_club", "Golf & Country Clubs"),
    ("historic_estate_mansion", "Historic Estates & Mansions"),
    ("hotel_inn_resort", "Hotels, Inns & Resorts"),
    ("industrial_loft", "Industrial & Loft Spaces"),
    ("lodge_cabin_retreat", "Lodges, Cabins & Retreats"),
    ("museum_gallery_attraction", "Museums, Galleries & Attractions"),
    ("park_mountain_outdoor", "Parks, Mountains & Outdoor"),
    ("restaurant_brewery", "Restaurants & Breweries"),
    ("vineyard_winery", "Vineyards & Wineries"),
]

# (option_value, option_label, option_group, icon_name)
# icon_name must have an entry in lib/utils/amenity_icons.dart.
AMENITIES = [
    ("cleanup_included",      "Clean-Up Included",           "Included Services",         "cleaning_services"),
    ("event_coordinator",     "Event Coordinator",           "Included Services",         "manage_accounts"),
    ("event_staff",           "Event Staff",                 "Included Services",         "groups"),
    ("dj_mc_included",        "DJ/MC Included",              "Included Services",         "headphones"),
    ("tables_chairs_linens",  "Tables, Chairs & Linens",     "Included Services",         "table_restaurant"),

    ("sound_system",          "Sound System",                "Equipment & A/V",           "speaker"),
    ("event_lighting",        "Event Lighting",              "Equipment & A/V",           "lightbulb"),
    ("av_projection",         "A/V & Projection",            "Equipment & A/V",           "videocam"),
    ("wifi",                  "Wi-Fi",                       "Equipment & A/V",           "wifi"),

    ("dance_floor",           "Dance Floor",                 "Facilities",                "nightlife"),
    ("bridal_suite",          "Dressing Room / Bridal Suite","Facilities",                "checkroom"),
    ("commercial_kitchen",    "Commercial Kitchen",          "Facilities",                "kitchen"),
    ("permanent_restrooms",   "Permanent Restrooms",         "Facilities",                "wc"),
    ("hvac",                  "Heating & A/C",               "Facilities",                "thermostat"),

    ("wheelchair_accessible", "Wheelchair Accessible",       "Accessibility & Policies",  "accessible"),
    ("insurance_required",    "Liability Insurance Required","Accessibility & Policies",  "policy"),
]

# filter_key, filter_label, filter_type, display_order, range config
# display_order puts Venue Type first; the surviving legacy groups
# (setting_type, catering) sit at 20 and 30.
FILTER_GROUPS = [
    (VENUE_TYPE_KEY, "Venue Type", "chips", 0, None),
    (AMENITIES_KEY,  "Amenities",  "chips", 10, None),
    (PRICE_KEY,      "Starting Price", "range", 40,
     {"range_min": 0, "range_max": 20000, "range_step": 500, "range_unit": "$"}),
    (CAPACITY_KEY,   "Guest Capacity", "range", 50,
     {"range_min": 0, "range_max": 1000, "range_step": 25, "range_unit": "guests"}),
]

# Superseded by the new taxonomy and deleted during the 2026-08-09 seed:
#   venue_style  -> its 7 options are a strict subset of the 13 venue types
#   capacity     -> replaced by the guest_capacity_range slider
#   price_range  -> replaced by the starting_price slider
# Safe to delete because no vendor row had any filter_values set.
RETIRED_KEYS = ["venue_style", "capacity", "price_range"]


def client() -> Client:
    key = os.environ.get("SUPABASE_SERVICE_KEY")
    if not key:
        sys.exit(
            "SUPABASE_SERVICE_KEY is not set.\n"
            "  PowerShell: $env:SUPABASE_SERVICE_KEY = \"...\"\n"
            "  bash:       export SUPABASE_SERVICE_KEY=\"...\""
        )
    return create_client(URL, key)


# ----------------------------------------------------------------- inspect --

def inspect(sb: Client) -> None:
    print(f"=== category_filters for {CATEGORY!r} ===")
    groups = (
        sb.table("category_filters").select("*").eq("category_name", CATEGORY).execute().data
    )
    if not groups:
        print("  (none)")
    for g in groups:
        ftype = g.get("filter_type", "chips")
        print(f"\n  filter_key   : {g.get('filter_key')}")
        print(f"  filter_label : {g.get('filter_label')}")
        print(f"  filter_type  : {ftype}")
        legacy = g.get("options")
        if legacy:
            print(f"  options[]    : {legacy}")

    print("\n=== filter_options rows ===")
    keys = [g.get("filter_key") for g in groups if g.get("filter_key")]
    if keys:
        rows = (
            sb.table("filter_options")
            .select("*")
            .in_("filter_key", keys)
            .order("filter_key")
            .order("display_order")
            .execute()
            .data
        )
        if not rows:
            print("  (none yet)")
        for r in rows:
            grp = f"[{r['option_group']}] " if r.get("option_group") else ""
            print(f"  {r['filter_key']:24} {grp}{r['option_value']:26} {r['option_label']}")

    print("\n=== distinct filter_values keys currently used by Venue vendors ===")
    vendors = (
        sb.table("vendors")
        .select("vendor_id, vendor_name, filter_values, starting_price, capacity_min, capacity_max")
        .eq("vendor_category", CATEGORY)
        .execute()
        .data
    )
    seen: dict[str, set] = {}
    for v in vendors:
        for k, vals in (v.get("filter_values") or {}).items():
            seen.setdefault(k, set()).update(vals if isinstance(vals, list) else [vals])
    if not seen:
        print("  (no vendor has filled any filters in)")
    for k, vals in sorted(seen.items()):
        print(f"  {k:24} {sorted(vals)}")
    print(f"\n  {len(vendors)} Venue vendors total")


# -------------------------------------------------------------------- seed --

def seed(sb: Client) -> None:
    existing = {
        g["filter_key"]
        for g in sb.table("category_filters")
        .select("filter_key")
        .eq("category_name", CATEGORY)
        .execute()
        .data
    }

    for key in RETIRED_KEYS:
        if key in existing:
            sb.table("category_filters").delete().eq(
                "category_name", CATEGORY
            ).eq("filter_key", key).execute()
            print(f"group   {key:24} RETIRED (superseded)")

    for key, label, ftype, order, ranges in FILTER_GROUPS:
        if key in existing:
            print(f"group   {key:24} already exists, skipped")
            continue
        row = {
            "category_name": CATEGORY,
            "filter_key": key,
            "filter_label": label,
            "filter_type": ftype,
            "display_order": order,
            # options is NOT NULL with no default. An empty array means
            # "no legacy options, read filter_options instead".
            "options": [],
            # Range groups are a single band, not a multi-pick chip list.
            "multi_select": ftype != "range",
        }
        if ranges:
            row.update(ranges)
        sb.table("category_filters").insert(row).execute()
        print(f"group   {key:24} inserted")

    options = [
        {
            "filter_key": VENUE_TYPE_KEY,
            "option_value": value,
            "option_label": label,
            "option_group": None,
            "icon_name": None,
            "display_order": i * 10,
        }
        for i, (value, label) in enumerate(VENUE_TYPES)
    ] + [
        {
            "filter_key": AMENITIES_KEY,
            "option_value": value,
            "option_label": label,
            "option_group": group,
            "icon_name": icon,
            "display_order": i * 10,
        }
        for i, (value, label, group, icon) in enumerate(AMENITIES)
    ]

    sb.table("filter_options").upsert(
        options, on_conflict="filter_key,option_value"
    ).execute()
    print(f"options {len(options)} rows upserted "
          f"({len(VENUE_TYPES)} venue types, {len(AMENITIES)} amenities)")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--inspect", action="store_true", help="read-only dump of what exists")
    p.add_argument("--seed", action="store_true", help="insert the venue taxonomy")
    args = p.parse_args()

    if not (args.inspect or args.seed):
        p.print_help()
        return

    sb = client()
    if args.inspect:
        inspect(sb)
    if args.seed:
        seed(sb)


if __name__ == "__main__":
    main()
