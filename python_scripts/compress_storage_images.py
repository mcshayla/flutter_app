"""
compress_storage_images.py

Scans the vendor-photos Supabase bucket, identifies images that exceed the
target spec (max 1200px long side, JPEG 75% quality), compresses them in place,
and re-uploads them.

Requirements:
    pip install supabase Pillow

Usage:
    # Dry run on one vendor (see what would change, no uploads)
    python compress_storage_images.py --vendor "Vendor Name"

    # Apply to one vendor
    python compress_storage_images.py --vendor "Vendor Name" --apply

    # Dry run on all vendors
    python compress_storage_images.py

    # Apply to all vendors
    python compress_storage_images.py --apply
"""

import argparse
import io
import sys
from supabase import create_client, Client
from PIL import Image

SUPABASE_URL = "https://cocmclecxanepyheygqs.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"
BUCKET = "vendor-photos"

# Must match the Flutter compressForUpload() settings
MAX_DIMENSION = 1200
JPEG_QUALITY = 75

# Files smaller than this are skipped entirely — already small enough
SKIP_BELOW_KB = 300

# Only compress files at least this large — targeting uncompressed uploads
COMPRESS_ABOVE_KB = 1024  # 1 MB

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".gif", ".bmp", ".jfif"}

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


def list_all_image_paths() -> list[tuple[str, int]]:
    """Returns list of (path, size_bytes) for every image in the bucket."""
    results = []

    top_level = supabase.storage.from_(BUCKET).list()
    for item in top_level:
        if item.get("id") is not None:
            # File at root level (unusual but handle it)
            _collect_file(item, "", results)
        else:
            # It's a vendor folder — list its contents
            folder = item["name"]
            files = supabase.storage.from_(BUCKET).list(folder)
            for f in files:
                _collect_file(f, folder, results)

    return results


def _collect_file(item: dict, folder: str, results: list):
    name: str = item["name"]
    ext = "." + name.rsplit(".", 1)[-1].lower() if "." in name else ""
    if ext not in IMAGE_EXTENSIONS:
        return
    path = f"{folder}/{name}" if folder else name
    size = (item.get("metadata") or {}).get("size", 0)
    results.append((path, size))


def compress_bytes(data: bytes) -> bytes:
    """Resize to MAX_DIMENSION on the long side and re-encode as JPEG."""
    img = Image.open(io.BytesIO(data))
    if img.mode in ("RGBA", "P", "LA"):
        img = img.convert("RGB")

    w, h = img.size
    if max(w, h) > MAX_DIMENSION:
        if w >= h:
            new_w, new_h = MAX_DIMENSION, max(1, int(h * MAX_DIMENSION / w))
        else:
            new_w, new_h = max(1, int(w * MAX_DIMENSION / h)), MAX_DIMENSION
        img = img.resize((new_w, new_h), Image.LANCZOS)

    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return buf.getvalue()


def needs_compression(data: bytes) -> tuple[bool, str]:
    """Returns (needs_compression, reason_string)."""
    kb = len(data) / 1024

    if kb < COMPRESS_ABOVE_KB:
        return False, f"{kb:.0f} KB — under {COMPRESS_ABOVE_KB} KB threshold"

    try:
        img = Image.open(io.BytesIO(data))
        w, h = img.size
    except Exception as e:
        return False, f"could not decode image: {e}"

    return True, f"{w}x{h}px  {kb:.0f} KB"


def main():
    parser = argparse.ArgumentParser(description="Compress oversized images in Supabase storage.")
    parser.add_argument("--apply", action="store_true", help="Actually compress and re-upload. Default is dry run.")
    parser.add_argument("--vendor", metavar="FOLDER", help="Only process this vendor folder (e.g. 'Bliss Photography').")
    args = parser.parse_args()

    dry_run = not args.apply

    if dry_run:
        print("DRY RUN — no changes will be made. Pass --apply to compress.\n")
    else:
        print("APPLYING — images will be compressed and re-uploaded.\n")

    print("Listing images in bucket...")
    all_images = list_all_image_paths()

    if args.vendor:
        all_images = [(p, s) for p, s in all_images if p.startswith(args.vendor + "/")]
        print(f"Filtered to vendor '{args.vendor}': {len(all_images)} image(s).\n")
    else:
        print(f"Found {len(all_images)} image(s) total.\n")

    skipped = 0
    already_ok = 0
    compressed = 0
    errors = 0
    bytes_saved_total = 0

    for path, size_bytes in all_images:
        size_kb = size_bytes / 1024

        if size_bytes > 0 and size_kb < SKIP_BELOW_KB:
            print(f"  SKIP   {path}  ({size_kb:.0f} KB — under {SKIP_BELOW_KB} KB)")
            skipped += 1
            continue

        # Download
        try:
            data: bytes = supabase.storage.from_(BUCKET).download(path)
        except Exception as e:
            print(f"  ERROR  {path}  — download failed: {e}")
            errors += 1
            continue

        needs, reason = needs_compression(data)

        if not needs:
            print(f"  OK     {path}  ({reason})")
            already_ok += 1
            continue

        compressed_data = compress_bytes(data)
        saved_kb = (len(data) - len(compressed_data)) / 1024
        bytes_saved_total += len(data) - len(compressed_data)

        print(f"  {'WOULD COMPRESS' if dry_run else 'COMPRESSING'}  {path}  ({reason}  →  {len(compressed_data)//1024} KB,  saves {saved_kb:.0f} KB)")

        if not dry_run:
            try:
                supabase.storage.from_(BUCKET).update(
                    path,
                    compressed_data,
                    file_options={"content-type": "image/jpeg", "upsert": "true"},
                )
            except Exception as e:
                print(f"           upload failed: {e}")
                errors += 1
                continue

        compressed += 1

    print(f"""
Summary
-------
Total images : {len(all_images)}
Skipped      : {skipped}  (under {SKIP_BELOW_KB} KB)
Already OK   : {already_ok}  (under {COMPRESS_ABOVE_KB} KB threshold)
Compressed   : {compressed}
Errors       : {errors}
Bytes saved  : {bytes_saved_total // 1024} KB  {'(dry run — not applied)' if dry_run else '(saved)'}
""")

    if dry_run and compressed > 0:
        print("Run with --apply to apply the changes.")


if __name__ == "__main__":
    main()
