// Conditional export: dart:html (web) vs url_launcher (native/desktop).
// This avoids mobile-browser popup blocking caused by the async gap between
// the user tap and the URL becoming available.
export 'launch_url_helper_stub.dart'
    if (dart.library.html) 'launch_url_helper_web.dart';
