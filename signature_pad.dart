import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'app_core.dart';

/// A simple finger-drawing signature pad. No external package needed —
/// just Flutter's CustomPainter + RepaintBoundary.
///
/// Usage:
///   final sigKey = GlobalKey<SignaturePadState>();
///   SignaturePad(key: sigKey)
///   ...
///   final bytes = await sigKey.currentState?.exportPng(); // PNG bytes or null
///   sigKey.currentState?.clear();
///   final empty = sigKey.currentState?.isEmpty ?? true;
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final GlobalKey _repaintKey = GlobalKey();
  List<Offset?> _points = [];

  bool get isEmpty => _points.isEmpty;

  void clear() => setState(() => _points = []);

  /// Renders the current strokes to a PNG and returns the bytes.
  Future<Uint8List?> exportPng() async {
    if (_points.isEmpty) return null;
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12, width: 1.2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: GestureDetector(
            onPanUpdate: (details) {
              final box = context.findRenderObject() as RenderBox;
              final point = box.globalToLocal(details.globalPosition);
              setState(() => _points = List<Offset?>.from(_points)..add(point));
            },
            onPanEnd: (_) {
              setState(() => _points = List<Offset?>.from(_points)..add(null));
            },
            child: CustomPaint(
              painter: _SignaturePainter(_points),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = navy
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
