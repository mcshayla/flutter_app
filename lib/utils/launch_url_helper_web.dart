// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Redirects the current browser tab to [url].
/// Same-tab navigation is never blocked by popup blockers, which is critical
/// on mobile browsers where window.open() (used by url_launcher) is blocked
/// when called after an async gap.
Future<void> launchCheckoutUrl(String url) async {
  html.window.location.href = url;
}
