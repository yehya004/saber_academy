import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';

enum EditorMode {
  none,
  pen,
  highlighter,
}

class TextOverlay {
  final String id;
  String text;
  Offset offset;
  Color color;
  double fontSize;

  TextOverlay({
    required this.id,
    required this.text,
    required this.offset,
    required this.color,
    this.fontSize = 24.0,
  });
}

class StampOverlay {
  final String id;
  final String type; // 'check' or 'cross'
  Offset offset;
  double scale;

  StampOverlay({
    required this.id,
    required this.type,
    required this.offset,
    this.scale = 1.0,
  });
}

class DrawingPath {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  DrawingPath({
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.isHighlighter,
  });
}

class ImageEditorScreen extends StatefulWidget {
  final File imageFile;

  const ImageEditorScreen({super.key, required this.imageFile});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();

  double _imageAspectRatio = 1.0;
  bool _imageLoaded = false;

  EditorMode _currentMode = EditorMode.none;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 5.0;

  final List<DrawingPath> _paths = [];
  DrawingPath? _currentPath;

  final List<TextOverlay> _textOverlays = [];
  final List<StampOverlay> _stampOverlays = [];

  String? _selectedItemId;
  String? _selectedItemType; // 'text' or 'stamp'

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
  }

  Future<void> _loadImageDimensions() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _imageAspectRatio = frame.image.width / frame.image.height;
          _imageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading image dimensions: $e");
      if (mounted) {
        setState(() {
          _imageAspectRatio = 1.0;
          _imageLoaded = true;
        });
      }
    }
  }

  void _addTextOverlay() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final textController = TextEditingController();
    Color dialogSelectedColor = _selectedColor;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isAr ? 'إضافة نص' : (isTr ? 'Metin Ekle' : 'Add Text'),
          style: const TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: textController,
                    style: TextStyle(color: dialogSelectedColor, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: isAr ? 'اكتب هنا...' : (isTr ? 'Buraya yazın...' : 'Type here...'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.yellow,
                    Colors.white,
                    Colors.black,
                  ].map((color) {
                    final isSelected = dialogSelectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          dialogSelectedColor = color;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.grey[600]!,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAr ? 'إلغاء' : (isTr ? 'İptal' : 'Cancel'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  final newOverlay = TextOverlay(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    text: val,
                    offset: const Offset(100, 150),
                    color: dialogSelectedColor,
                  );
                  _textOverlays.add(newOverlay);
                  _selectedItemId = newOverlay.id;
                  _selectedItemType = 'text';
                  _currentMode = EditorMode.none;
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isAr ? 'إضافة' : (isTr ? 'Ekle' : 'Add')),
          ),
        ],
      ),
    );
  }

  void _editTextOverlay(TextOverlay overlay) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final textController = TextEditingController(text: overlay.text);
    Color dialogSelectedColor = overlay.color;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          isAr ? 'تعديل النص' : (isTr ? 'Metni Düzenle' : 'Edit Text'),
          style: const TextStyle(color: Colors.white),
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: textController,
                    style: TextStyle(color: dialogSelectedColor, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: isAr ? 'اكتب هنا...' : (isTr ? 'Buraya yazın...' : 'Type here...'),
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.yellow,
                    Colors.white,
                    Colors.black,
                  ].map((color) {
                    final isSelected = dialogSelectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          dialogSelectedColor = color;
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blueAccent : Colors.grey[600]!,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isAr ? 'إلغاء' : (isTr ? 'İptal' : 'Cancel'),
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  overlay.text = val;
                  overlay.color = dialogSelectedColor;
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isAr ? 'حفظ' : (isTr ? 'Kaydet' : 'Save')),
          ),
        ],
      ),
    );
  }

  void _addStamp(String type) {
    setState(() {
      final newStamp = StampOverlay(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        offset: const Offset(120, 180),
      );
      _stampOverlays.add(newStamp);
      _selectedItemId = newStamp.id;
      _selectedItemType = 'stamp';
      _currentMode = EditorMode.none;
    });
  }

  Future<void> _saveImage() async {
    // Deselect any items before rendering to prevent selection border from showing on output
    setState(() {
      _selectedItemId = null;
      _selectedItemType = null;
    });

    // Let UI rebuild without selection borders
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      debugPrint("Error saving edited image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isAr ? 'تعديل الصورة' : (isTr ? 'Resmi Düzenle' : 'Edit Image'),
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_paths.isNotEmpty || _textOverlays.isNotEmpty || _stampOverlays.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_paths.isNotEmpty) {
                    _paths.removeLast();
                  } else if (_textOverlays.isNotEmpty) {
                    _textOverlays.removeLast();
                  } else if (_stampOverlays.isNotEmpty) {
                    _stampOverlays.removeLast();
                  }
                });
              },
            ),
          TextButton(
            onPressed: _saveImage,
            child: Text(
              isAr ? 'إرسال' : (isTr ? 'Gönder' : 'Send'),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: !_imageLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.grey[950],
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: AspectRatio(
                          aspectRatio: _imageAspectRatio,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final canvasWidth = constraints.maxWidth;
                              final canvasHeight = constraints.maxHeight;

                              return RepaintBoundary(
                                key: _boundaryKey,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  fit: StackFit.expand,
                                  children: [
                                    // Base Image
                                    Image.file(
                                      widget.imageFile,
                                      fit: BoxFit.fill,
                                    ),

                                    // Drawing overlay
                                    GestureDetector(
                                      onPanStart: (details) {
                                        if (_currentMode == EditorMode.none) {
                                          // Deselect active items if tapping raw canvas in select mode
                                          setState(() {
                                            _selectedItemId = null;
                                            _selectedItemType = null;
                                          });
                                          return;
                                        }
                                        setState(() {
                                          final renderBox = context.findRenderObject() as RenderBox?;
                                          final localPos = renderBox?.globalToLocal(details.globalPosition) ?? Offset.zero;
                                          _currentPath = DrawingPath(
                                            points: [localPos],
                                            color: _currentMode == EditorMode.highlighter
                                                ? _selectedColor.withValues(alpha: 0.4)
                                                : _selectedColor,
                                            strokeWidth: _currentMode == EditorMode.highlighter ? 24.0 : _strokeWidth,
                                            isHighlighter: _currentMode == EditorMode.highlighter,
                                          );
                                        });
                                      },
                                      onPanUpdate: (details) {
                                        if (_currentMode == EditorMode.none || _currentPath == null) return;
                                        setState(() {
                                          final renderBox = context.findRenderObject() as RenderBox?;
                                          final localPos = renderBox?.globalToLocal(details.globalPosition) ?? Offset.zero;
                                          _currentPath!.points.add(localPos);
                                        });
                                      },
                                      onPanEnd: (details) {
                                        if (_currentPath != null) {
                                          setState(() {
                                            _paths.add(_currentPath!);
                                            _currentPath = null;
                                          });
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: ImagePainter(
                                          paths: _paths,
                                          currentPath: _currentPath,
                                        ),
                                        size: Size.infinite,
                                      ),
                                    ),

                                    // Stamps overlays
                                    ..._stampOverlays.map((stamp) {
                                      final isSelected = _selectedItemId == stamp.id && _selectedItemType == 'stamp';
                                      return Positioned(
                                        left: stamp.offset.dx,
                                        top: stamp.offset.dy,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              // Clamp to canvas borders
                                              final newX = (stamp.offset.dx + details.delta.dx).clamp(-20.0, canvasWidth - 20.0);
                                              final newY = (stamp.offset.dy + details.delta.dy).clamp(-20.0, canvasHeight - 20.0);
                                              stamp.offset = Offset(newX, newY);
                                            });
                                          },
                                          onTap: () {
                                            setState(() {
                                              _selectedItemId = stamp.id;
                                              _selectedItemType = 'stamp';
                                            });
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  border: isSelected
                                                      ? Border.all(color: Colors.blueAccent, width: 1.5)
                                                      : null,
                                                ),
                                                child: stamp.type == 'check'
                                                    ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48)
                                                    : const Icon(Icons.cancel_rounded, color: Colors.red, size: 48),
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  top: -12,
                                                  right: -12,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _stampOverlays.removeWhere((o) => o.id == stamp.id);
                                                        _selectedItemId = null;
                                                        _selectedItemType = null;
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding: const EdgeInsets.all(4),
                                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),

                                    // Text overlays
                                    ..._textOverlays.map((overlay) {
                                      final isSelected = _selectedItemId == overlay.id && _selectedItemType == 'text';
                                      return Positioned(
                                        left: overlay.offset.dx,
                                        top: overlay.offset.dy,
                                        child: GestureDetector(
                                          onPanUpdate: (details) {
                                            setState(() {
                                              // Clamp to canvas borders
                                              final newX = (overlay.offset.dx + details.delta.dx).clamp(-20.0, canvasWidth - 20.0);
                                              final newY = (overlay.offset.dy + details.delta.dy).clamp(-20.0, canvasHeight - 20.0);
                                              overlay.offset = Offset(newX, newY);
                                            });
                                          },
                                          onTap: () {
                                            setState(() {
                                              _selectedItemId = overlay.id;
                                              _selectedItemType = 'text';
                                            });
                                          },
                                          onDoubleTap: () {
                                            _editTextOverlay(overlay);
                                          },
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: isSelected
                                                      ? Border.all(color: Colors.blueAccent, width: 1.5)
                                                      : null,
                                                ),
                                                child: Text(
                                                  overlay.text,
                                                  style: TextStyle(
                                                    color: overlay.color,
                                                    fontSize: overlay.fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isSelected)
                                                Positioned(
                                                  top: -12,
                                                  right: -12,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _textOverlays.removeWhere((o) => o.id == overlay.id);
                                                        _selectedItemId = null;
                                                        _selectedItemType = null;
                                                      });
                                                    },
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      padding: const EdgeInsets.all(4),
                                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Colors & Width sliders
                if (_currentMode != EditorMode.none) ...[
                  Container(
                    color: Colors.grey[950],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildColorDot(Colors.red),
                        _buildColorDot(Colors.green),
                        _buildColorDot(Colors.blue),
                        _buildColorDot(Colors.yellow),
                        _buildColorDot(Colors.white),
                        _buildColorDot(Colors.black),
                      ],
                    ),
                  ),
                  if (_currentMode == EditorMode.pen)
                    Container(
                      color: Colors.grey[950],
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.line_weight, color: Colors.white70, size: 20),
                          Expanded(
                            child: Slider(
                              value: _strokeWidth,
                              min: 2.0,
                              max: 20.0,
                              activeColor: _selectedColor,
                              onChanged: (val) {
                                setState(() {
                                  _strokeWidth = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                // Bottom bar
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildToolButton(
                          mode: EditorMode.none,
                          icon: Icons.select_all_rounded,
                          label: isAr ? 'تحديد' : (isTr ? 'Seç' : 'Select'),
                        ),
                        _buildToolButton(
                          mode: EditorMode.pen,
                          icon: Icons.edit_rounded,
                          label: isAr ? 'قلم' : (isTr ? 'Kalem' : 'Pen'),
                        ),
                        _buildToolButton(
                          mode: EditorMode.highlighter,
                          icon: Icons.highlight_rounded,
                          label: isAr ? 'تظليل' : (isTr ? 'Vurgula' : 'Highlight'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.text_fields_rounded, color: Colors.white, size: 28),
                          onPressed: _addTextOverlay,
                          tooltip: isAr ? 'إضافة نص' : (isTr ? 'Metin Ekle' : 'Add Text'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 28),
                          onPressed: () => _addStamp('check'),
                          tooltip: isAr ? 'علامة صح' : (isTr ? 'Doğru İşareti' : 'Check Mark'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 28),
                          onPressed: () => _addStamp('cross'),
                          tooltip: isAr ? 'علامة خطأ' : (isTr ? 'Yanlış İşareti' : 'Cross Mark'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          // Apply color to selected text overlay if any
          if (_selectedItemId != null && _selectedItemType == 'text') {
            final idx = _textOverlays.indexWhere((o) => o.id == _selectedItemId);
            if (idx != -1) {
              _textOverlays[idx].color = color;
            }
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[800]!,
            width: isSelected ? 3.0 : 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required EditorMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentMode == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _currentMode = mode;
          if (mode != EditorMode.none) {
            _selectedItemId = null;
            _selectedItemType = null;
          }
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : Colors.white60,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white60,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final List<DrawingPath> paths;
  final DrawingPath? currentPath;

  ImagePainter({required this.paths, this.currentPath});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawDrawingPath(DrawingPath dp) {
      if (dp.points.isEmpty) return;
      paint.color = dp.color;
      paint.strokeWidth = dp.strokeWidth;

      if (dp.isHighlighter) {
        paint.blendMode = BlendMode.srcOver;
      } else {
        paint.blendMode = BlendMode.srcOver;
      }

      if (dp.points.length == 1) {
        canvas.drawCircle(dp.points.first, dp.strokeWidth / 2, paint);
      } else {
        for (int i = 0; i < dp.points.length - 1; i++) {
          canvas.drawLine(dp.points[i], dp.points[i + 1], paint);
        }
      }
    }

    for (final path in paths) {
      drawDrawingPath(path);
    }
    if (currentPath != null) {
      drawDrawingPath(currentPath!);
    }
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) => true;
}
