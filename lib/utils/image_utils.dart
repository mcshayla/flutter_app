/// Images are compressed at upload time, so no transform needed at serve time.
String supabaseThumb(String url, {int width = 400, int quality = 70}) => url;

/// Strips characters that are invalid in Supabase storage paths (e.g. |, /, ?)
/// while keeping the vendor's display name unchanged in the database.
String sanitizeStorageName(String name) {
  return name.replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '_').trim();
}
