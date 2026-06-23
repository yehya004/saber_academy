// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

// Keep track of already registered platform views to prevent registry collision crash on Web
final Set<String> _registeredViews = {};

Widget buildPlatformSpecificImage({
  required String imageUrl,
  required double width,
  required double height,
  required BoxFit fit,
}) {
  final String wStr = width.isFinite ? width.toInt().toString() : 'inf';
  final String hStr = height.isFinite ? height.toInt().toString() : 'inf';
  final String viewType = 'img-${imageUrl.hashCode}-$wStr-$hStr';
  
  // Register the view factory if not already registered
  if (!_registeredViews.contains(viewType)) {
    _registeredViews.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final element = html.ImageElement()
      ..src = imageUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = 'none';

    void disableParentPointerEvents() {
      try {
        html.Element? parent = element.parent;
        int depth = 0;
        while (parent != null && depth < 5) {
          if (parent.tagName.toLowerCase() == 'flt-platform-view') {
            parent.style.pointerEvents = 'none';
            break;
          }
          parent = parent.parent;
          depth++;
        }
      } catch (e) {
        // ignore
      }
    }

    element.onLoad.listen((_) => disableParentPointerEvents());
    
    for (final ms in [50, 150, 300, 600, 1200]) {
      Future.delayed(Duration(milliseconds: ms), disableParentPointerEvents);
    }

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
  }

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
