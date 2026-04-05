/// Images are compressed at upload time, so no transform needed at serve time.
String supabaseThumb(String url, {int width = 400, int quality = 70}) => url;
