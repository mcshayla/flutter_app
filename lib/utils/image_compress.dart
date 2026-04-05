import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Compresses [bytes] to JPEG, max 1200px on the long side, 75% quality.
/// Uses the pure-Dart `image` package on web and flutter_image_compress on native.
Future<Uint8List> compressForUpload(Uint8List bytes) async {
  if (kIsWeb) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    final resized = decoded.width > decoded.height
        ? img.copyResize(decoded, width: 1200)
        : img.copyResize(decoded, height: 1200);
    return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
  } else {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 1200,
      minHeight: 1200,
      quality: 75,
      format: CompressFormat.jpeg,
    );
    return compressed ?? bytes;
  }
}
