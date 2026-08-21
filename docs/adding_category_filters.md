# Adding in-depth filters for a vendor category

Venue is done and is the worked example. This is the recipe for every other
category (Catering, Photographer, Florist, …).

**The point: adding filters is a data task, not a deploy.** Filter groups and
their options are rows. The filter sheet, the vendor edit form, and the vendor
detail page all render generically from those rows. You should not need to
touch Dart to add "Cuisine" to Catering.

The one exception is icons — see step 4.

---

## The two tables

| Table | Holds | One row per |
|---|---|---|
| `category_filters` | the filter **group** | Venue Type, Amenities, Cuisine … |
| `filter_options` | the selectable **options** | Barn, Wi-Fi, Vegan … |

`category_filters` columns that matter:

- `category_name` — must match `vendors.vendor_category` **exactly**.
- `filter_key` — the key written into `vendors.filter_values` jsonb. Globally
  unique, not just per-category. Prefix it (`catering_cuisine`, not `cuisine`)
  so two categories can't collide.
- `filter_label` — what the couple sees.
- `filter_type` — `'chips'` (multi-select tags) or `'range'` (numeric slider).
- `range_min` / `range_max` / `range_step` / `range_unit` — only for `'range'`.
- `options` — **jsonb, NOT NULL, no default.** Always set it. Use `'[]'` for
  new groups, meaning "no legacy options, read `filter_options` instead".
- `multi_select` — `true` for chips, `false` for range.
- `display_order` — ascending, controls sheet order.

`filter_options` columns:

- `filter_key` — joins to the group.
- `option_value` — what's stored in `filter_values`. Stable, snake_case,
  never re-used. Renaming one orphans every vendor who picked it.
- `option_label` — what's displayed. Safe to change any time.
- `option_group` — optional sub-heading. Groups render as sub-sections in the
  filter sheet and on the detail page (wide layout only).
- `icon_name` — see step 4. `NULL` for plain option lists.
- `display_order` — ascending within the group.
- `UNIQUE (filter_key, option_value)` — makes seeding idempotent.

---

## Step 1 — Design the taxonomy first, on paper

Two rules learned from the Venue pass:

**Check for overlap with what already exists.** Venue already had a
`venue_style` group (Barn, Estate, Hotel, Garden, …) that turned out to be a
strict subset of the new 13-item Venue Type. Shipping both would have given
couples two lists that mean the same thing. Query first:

```sql
select filter_key, filter_label, options
from category_filters
where category_name = 'Catering'
order by display_order;
```

**Every group must be one axis.** "Urban" was dropped from the Venue taxonomy
because it didn't fit: Setting Type is Indoor/Outdoor/Both (an enclosure axis),
and Urban is a locale. Mixing axes in one group makes the filter meaningless —
you can't OR "Indoor" against "Urban" and get a sensible result. If an option
cuts across every other option in the group, it belongs in its own group or
nowhere.

Aim for 8–16 options per group. Under ~6 the filter rarely narrows anything;
over ~20 it becomes a wall.

---

## Step 2 — Check whether retiring old groups is free

```sql
select count(*) from vendors
where vendor_category = 'Catering'
  and filter_values ? 'the_old_key';
```

Zero means you can delete the old group outright — no data migration. That was
true for the whole Venue pass (only one vendor in the entire database had any
`filter_values` set). It will get less true as vendors fill in profiles, so do
the cleanup early.

If it's non-zero, either keep the old group or write an UPDATE remapping old
`option_value`s to new ones before deleting.

---

## Step 3 — Seed it

Use the Supabase MCP `apply_migration` tool. DDL and seeds both work there;
`supabase-py` cannot do DDL (it goes through PostgREST, which has no
`CREATE TABLE` path). The dashboard is not required.

```sql
INSERT INTO category_filters
  (category_name, filter_key, filter_label, options, multi_select,
   display_order, filter_type)
VALUES
  ('Catering','catering_cuisine','Cuisine','[]'::jsonb, true, 0, 'chips');

INSERT INTO filter_options
  (filter_key, option_value, option_label, option_group, icon_name, display_order)
VALUES
  ('catering_cuisine','italian','Italian',NULL,NULL,0),
  ('catering_cuisine','mexican','Mexican',NULL,NULL,10)
ON CONFLICT (filter_key, option_value) DO NOTHING;
```

`display_order` in tens leaves room to insert later without renumbering.

`python_scripts/seed_venue_filters.py` is the reference implementation if you
prefer a script — copy its structure, including the `options: []` and
`multi_select` fields that are easy to forget.

---

## Step 3b — Relabelling an option without breaking vendor data

`option_value` is what's stored on the vendor; `option_label` is what's shown.
Keeping them separate is what lets you fix wording later. Worked example: Venue
Setting Type offered "Both", which reads as a shrug — it should say
"Indoor & Outdoor".

A group still on the legacy array has no label column, so migrate it first,
**reusing the stored strings as `option_value`**:

```sql
INSERT INTO filter_options
  (filter_key, option_value, option_label, option_group, icon_name, display_order)
VALUES
  ('setting_type','Indoor','Indoor',NULL,NULL,0),
  ('setting_type','Outdoor','Outdoor',NULL,NULL,10),
  ('setting_type','Both','Indoor & Outdoor',NULL,NULL,20)
ON CONFLICT (filter_key, option_value)
  DO UPDATE SET option_label = EXCLUDED.option_label;

UPDATE category_filters SET options = '[]'::jsonb
WHERE category_name = 'Venue' AND filter_key = 'setting_type';
```

Every vendor who picked "Both" keeps matching — nothing in `filter_values`
changes. Verify with the query in step 5 before moving on.

**Never** rename an `option_value` to fix wording. That orphans every vendor
who selected it, silently: they stop matching the filter and the value falls
through to the "renamed away" path on the detail page.

## Step 4 — Icons, only if the group deserves them

**A group whose options carry `icon_name` is treated as "amenity-like"** by
`VendorDetailsSection`: on the detail page it renders as icon cards (a
sideways strip on mobile, grouped pills on web) instead of a text spec line.
That is the whole switch — there is no per-category configuration.

So: set `icon_name` for feature checklists (Amenities, Included Services).
Leave it `NULL` for descriptive lists (Cuisine, Style) that read better as
text.

Icons are the one part that **does** need a deploy. Flutter tree-shakes unused
icons out of the built font, so an `IconData` cannot be constructed from an
arbitrary runtime string — it would render a blank glyph in release. The map
lives in `lib/utils/amenity_icons.dart`:

- Assigning an **existing** name to a new option → data only, no deploy.
- Introducing a **new** icon → add it to that map, then deploy.
- An unknown name degrades to a generic check icon, it does not crash.

---

## Step 5 — Verify before trusting it

Referential check — catches typos that would silently never match:

```sql
with vals as (
  select key as filter_key, jsonb_array_elements_text(value) as val
  from vendors, jsonb_each(filter_values)
  where vendor_id = '<the vendor>'
)
select v.filter_key, v.val,
       case when fo.option_value is not null then 'OK'
            when cf.options ? v.val then 'OK (legacy array)'
            else '*** UNRESOLVED ***' end as status
from vals v
left join filter_options fo
       on fo.filter_key = v.filter_key and fo.option_value = v.val
left join category_filters cf on cf.filter_key = v.filter_key;
```

Then seed one sample vendor with the new fields filled in and open its page.

---

## What renders where

| Surface | File | Notes |
|---|---|---|
| Filter sheet | `lib/templates/category_template.dart` | branches on `filter_type`, renders `option_group` sub-headings |
| Vendor detail page | `lib/widgets/vendor_details_section.dart` | specs as text, icon groups as cards; below the description |
| Amenity presentation | `lib/widgets/amenity_row.dart` | `AmenityLayout.grouped` (wide) / `.scroller` (mobile) |
| Vendor edit form | `lib/pages/vendor_edit_profile.dart` | skips `range` groups; they're numeric columns |
| Matching logic | `lib/services/vendor_filter.dart` | pure functions, unit-tested, no Flutter import |

## Gotchas

- `'Any'` is a **vendor-side wildcard** on state/county meaning "serves
  anywhere". It must match every selection and must never appear as a
  selectable option.
- Range groups are backed by real columns (`starting_price`, `capacity_min`,
  `capacity_max`), **not** `filter_values`. A null value is excluded as soon as
  the band is touched, so a category gets range filters only once its vendors
  actually have the numbers.
- Absence in `filter_values` means "never filled in", not "doesn't have it".
  Never render a negative state from it.
