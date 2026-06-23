import 'drag_drop_helper_stub.dart'
    if (dart.library.html) 'drag_drop_helper_web.dart';

class DragDropHelper {
  static void initialize({
    required void Function(bool isDragging) onDragStateChanged,
  }) {
    initializeDragDropPlatform(onDragStateChanged: onDragStateChanged);
  }

  static void dispose() {
    disposeDragDropPlatform();
  }
}
