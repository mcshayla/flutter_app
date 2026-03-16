import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an external browser on native platforms.
Future<void> launchCheckoutUrl(String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched) throw Exception('Could not open payment page');
}
