/// Converts a Supabase Storage public URL to a resized/compressed transform URL.
/// Non-Supabase URLs (e.g. picsum placeholders) are returned unchanged.
String supabaseThumb(String url, {int width = 400, int quality = 70}) {
  const marker = '/storage/v1/object/public/';
  if (!url.contains(marker)) return url;
  final transformed = url.replaceFirst('/object/', '/render/image/');
  return '$transformed?width=$width&quality=$quality&resize=contain';
}
