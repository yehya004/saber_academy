import 'package:flutter/material.dart';

Widget buildPlatformSpecificImage({
  required String imageUrl,
  required double width,
  required double height,
  required BoxFit fit,
}) {
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : SizedBox(
            width: width,
            height: height,
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          ),
    errorBuilder: (_, __, ___) => SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    ),
  );
}
