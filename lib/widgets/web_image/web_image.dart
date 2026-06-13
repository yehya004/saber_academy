import 'package:flutter/material.dart';
import 'web_image_stub.dart'
    if (dart.library.html) 'web_image_web.dart';

Widget buildWebFriendlyImage({
  required String imageUrl,
  required double width,
  required double height,
  BoxFit fit = BoxFit.cover,
}) {
  return buildPlatformSpecificImage(
    imageUrl: imageUrl,
    width: width,
    height: height,
    fit: fit,
  );
}
