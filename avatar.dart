import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Makes a square, small JPEG that the server accepts (10 KB or less).
/// Returns null if no size and quality setting gets under the limit.
Uint8List? prepareAvatar(Uint8List bytes) {
  final src = img.decodeImage(bytes);
  if (src == null) return null;
  final side = src.width < src.height ? src.width : src.height;
  final square = img.copyCrop(src,
      x: (src.width - side) ~/ 2, y: (src.height - side) ~/ 2, width: side, height: side);
  for (final size in const [192, 160, 128, 96, 80]) {
    final resized = img.copyResize(square, width: size, height: size);
    for (final quality in const [85, 75, 65, 55, 45]) {
      final out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
      if (out.length <= 9800) return out;
    }
  }
  return null;
}
