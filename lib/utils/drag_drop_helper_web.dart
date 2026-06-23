// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';

StreamSubscription<html.MouseEvent>? _onDragEnterSub;
StreamSubscription<html.MouseEvent>? _onDragOverSub;
StreamSubscription<html.MouseEvent>? _onDropSub;
Timer? _dragTimer;

void initializeDragDropPlatform({
  required void Function(bool isDragging) onDragStateChanged,
}) {
  _onDragEnterSub = html.window.onDragEnter.listen((event) {
    event.preventDefault();
  });

  _onDragOverSub = html.window.onDragOver.listen((event) {
    event.preventDefault();
    final types = event.dataTransfer.types;
    if (types != null && (types.contains('Files') || types.contains('files'))) {
      onDragStateChanged(true);
      _dragTimer?.cancel();
      _dragTimer = Timer(const Duration(milliseconds: 200), () {
        onDragStateChanged(false);
      });
    }
  });

  _onDropSub = html.window.onDrop.listen((event) {
    event.preventDefault();
    _dragTimer?.cancel();
    onDragStateChanged(false);
  });
}

void disposeDragDropPlatform() {
  _onDragEnterSub?.cancel();
  _onDragOverSub?.cancel();
  _onDropSub?.cancel();
  _dragTimer?.cancel();
}
