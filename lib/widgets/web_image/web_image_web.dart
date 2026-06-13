// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildPlatformSpecificImage({
  required String imageUrl,
  required double width,
  required double height,
  required BoxFit fit,
}) {
  final String viewType = 'img-${imageUrl.hashCode}-${width.toInt()}-${height.toInt()}';
  
  // Register the view factory
  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final element = html.ImageElement()
      ..src = imageUrl
      ..style.width = '100%'
      ..style.height = '100%';

    switch (fit) {
      case BoxFit.contain:
        element.style.objectFit = 'contain';
        break;
      case BoxFit.fill:
        element.style.objectFit = 'fill';
        break;
      case BoxFit.fitWidth:
        element.style.objectFit = 'scale-down';
        break;
      case BoxFit.fitHeight:
        element.style.objectFit = 'scale-down';
        break;
      case BoxFit.none:
        element.style.objectFit = 'none';
        break;
      default:
        element.style.objectFit = 'cover';
    }

    return element;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
