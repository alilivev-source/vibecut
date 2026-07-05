import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/localization/app_localizations.dart';

enum FaceFilterType { none, mustache, glasses, hat, beard, smooth, lips }

class FaceFiltersScreen extends StatefulWidget {
  final String lang;
  const FaceFiltersScreen({super.key, required this.lang});

  @override
  State<FaceFiltersScreen> createState() => _FaceFiltersScreenState();
}

class _FaceFiltersScreenState extends State<FaceFiltersScreen> {
  CameraController? _camera;
  FaceDetector? _detector;
  List<Face> _faces = [];
  FaceFilterType _selectedFilter = FaceFilterType.none;
  bool _isProcessing = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _permissionDenied = true);
      return;
    }
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _camera = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await _camera!.initialize();
    _detector = FaceDetector(options: FaceDetectorOptions(enableLandmarks: true));
    _camera!.startImageStream(_processFrame);
    if (mounted) setState(() {});
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || _detector == null || _selectedFilter == FaceFilterType.none) return;
    _isProcessing = true;
    try {
      final inputImage = InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final faces = await _detector!.processImage(inputImage);
      if (mounted) setState(() => _faces = faces);
    } catch (_) {}
    _isProcessing = false;
  }

  @override
  void dispose() {
    _camera?.dispose();
    _detector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text(AppLocalizations.t('camera_permission_needed', lang),
            style: const TextStyle(color: Colors.white))),
      );
    }
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(AppLocalizations.t('face_filters_title', lang)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(child: Text(AppLocalizations.t('face_filter_disclaimer', lang),
                style: const TextStyle(color: Colors.white38, fontSize: 9))),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_camera!),
                CustomPaint(
                  painter: _FacePainter(
                    faces: _faces,
                    filter: _selectedFilter,
                    previewSize: Size(
                      _camera!.value.previewSize!.height,
                      _camera!.value.previewSize!.width,
                    ),
                  ),
                ),
                if (_faces.isEmpty && _selectedFilter != FaceFilterType.none)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text(AppLocalizations.t('no_face_detected', lang),
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: FaceFilterType.values.map((f) {
                  final selected = f == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? Colors.amber : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(_filterIcon(f), color: selected ? Colors.black : Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(_filterLabel(f, lang),
                              style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _filterIcon(FaceFilterType f) {
    switch (f) {
      case FaceFilterType.none: return Icons.face_outlined;
      case FaceFilterType.mustache: return Icons.face;
      case FaceFilterType.glasses: return Icons.remove_red_eye_outlined;
      case FaceFilterType.hat: return Icons.face_retouching_natural;
      case FaceFilterType.beard: return Icons.face_2;
      case FaceFilterType.smooth: return Icons.blur_on;
      case FaceFilterType.lips: return Icons.favorite;
    }
  }

  String _filterLabel(FaceFilterType f, String lang) {
    switch (f) {
      case FaceFilterType.none: return AppLocalizations.t('face_filter_none', lang);
      case FaceFilterType.mustache: return AppLocalizations.t('face_filter_mustache', lang);
      case FaceFilterType.glasses: return AppLocalizations.t('face_filter_glasses', lang);
      case FaceFilterType.hat: return AppLocalizations.t('face_filter_hat', lang);
      case FaceFilterType.beard: return AppLocalizations.t('face_filter_beard', lang);
      case FaceFilterType.smooth: return AppLocalizations.t('face_filter_smooth', lang);
      case FaceFilterType.lips: return AppLocalizations.t('face_filter_lips', lang);
    }
  }
}

// رسم فلاتر الوجه فوق الكاميرا مباشرة بالكود
class _FacePainter extends CustomPainter {
  final List<Face> faces;
  final FaceFilterType filter;
  final Size previewSize;

  _FacePainter({required this.faces, required this.filter, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (filter == FaceFilterType.none) return;
    for (final face in faces) {
      final scaleX = size.width / previewSize.width;
      final scaleY = size.height / previewSize.height;

      Offset? scale(FaceLandmarkType type) {
        final lm = face.landmarks[type];
        if (lm == null) return null;
        return Offset(lm.position.x * scaleX, lm.position.y * scaleY);
      }

      final nose = scale(FaceLandmarkType.noseBase);
      final leftEye = scale(FaceLandmarkType.leftEye);
      final rightEye = scale(FaceLandmarkType.rightEye);
      final leftMouth = scale(FaceLandmarkType.leftMouth);
      final rightMouth = scale(FaceLandmarkType.rightMouth);
      final bottomMouth = scale(FaceLandmarkType.bottomMouth);

      final faceW = face.boundingBox.width * scaleX;
      final faceH = face.boundingBox.height * scaleY;
      final faceTop = face.boundingBox.top * scaleY;
      final faceLeft = face.boundingBox.left * scaleX;
      final faceCenterX = faceLeft + faceW / 2;

      switch (filter) {
        case FaceFilterType.mustache:
          if (nose == null) break;
          _drawMustache(canvas, nose, faceW * 0.35);
          break;

        case FaceFilterType.glasses:
          if (leftEye == null || rightEye == null) break;
          _drawGlasses(canvas, leftEye, rightEye, faceW * 0.22);
          break;

        case FaceFilterType.hat:
          _drawHat(canvas, Offset(faceCenterX, faceTop), faceW);
          break;

        case FaceFilterType.beard:
          if (bottomMouth == null) break;
          _drawBeard(canvas, bottomMouth, faceW * 0.45);
          break;

        case FaceFilterType.smooth:
          _drawSmooth(canvas, Offset(faceCenterX, faceTop + faceH / 2), faceW * 0.48, faceH * 0.52);
          break;

        case FaceFilterType.lips:
          if (leftMouth == null || rightMouth == null || bottomMouth == null) break;
          _drawLipstick(canvas, leftMouth, rightMouth, bottomMouth);
          break;

        default:
          break;
      }
    }
  }

  void _drawMustache(Canvas canvas, Offset nose, double width) {
    final paint = Paint()..color = const Color(0xFF3B1A0A)..style = PaintingStyle.fill;
    final path = Path();
    final left = Offset(nose.dx - width, nose.dy + width * 0.2);
    final right = Offset(nose.dx + width, nose.dy + width * 0.2);
    final bottom = Offset(nose.dx, nose.dy + width * 0.55);
    path.moveTo(left.dx, left.dy);
    path.cubicTo(left.dx + width * 0.5, left.dy - width * 0.5, nose.dx - width * 0.2, bottom.dy, bottom.dx, bottom.dy);
    path.cubicTo(nose.dx + width * 0.2, bottom.dy, right.dx - width * 0.5, right.dy - width * 0.5, right.dx, right.dy);
    path.cubicTo(right.dx - width * 0.3, right.dy + width * 0.3, left.dx + width * 0.3, left.dy + width * 0.3, left.dx, left.dy);
    canvas.drawPath(path, paint);
  }

  void _drawGlasses(Canvas canvas, Offset leftEye, Offset rightEye, double r) {
    final framePaint = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = r * 0.25;
    final lensPaint = Paint()..color = Colors.blue.withOpacity(0.25)..style = PaintingStyle.fill;
    canvas.drawCircle(leftEye, r, lensPaint);
    canvas.drawCircle(rightEye, r, lensPaint);
    canvas.drawCircle(leftEye, r, framePaint);
    canvas.drawCircle(rightEye, r, framePaint);
    // جسر النظارة
    canvas.drawLine(Offset(leftEye.dx + r, leftEye.dy), Offset(rightEye.dx - r, rightEye.dy), framePaint);
    // أذرع النظارة
    canvas.drawLine(Offset(leftEye.dx - r, leftEye.dy), Offset(leftEye.dx - r * 2.5, leftEye.dy - r * 0.5), framePaint);
    canvas.drawLine(Offset(rightEye.dx + r, rightEye.dy), Offset(rightEye.dx + r * 2.5, rightEye.dy - r * 0.5), framePaint);
  }

  void _drawHat(Canvas canvas, Offset top, double faceW) {
    final paint = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill;
    final brimPaint = Paint()..color = const Color(0xFF2C1A0E)..style = PaintingStyle.fill;
    final hatH = faceW * 0.65;
    final hatW = faceW * 0.6;
    final brimW = faceW * 0.85;
    final brimH = faceW * 0.12;
    // الحافة
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(top.dx, top.dy), width: brimW, height: brimH), const Radius.circular(5)),
      brimPaint,
    );
    // القبعة نفسها
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(top.dx - hatW / 2, top.dy - hatH, hatW, hatH), const Radius.circular(8)),
      paint,
    );
    // شريط القبعة
    final bandPaint = Paint()..color = Colors.amber..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(top.dx - hatW / 2, top.dy - hatH * 0.22, hatW, hatH * 0.12), bandPaint);
  }

  void _drawBeard(Canvas canvas, Offset bottomMouth, double width) {
    final paint = Paint()..color = const Color(0xFF3B1A0A).withOpacity(0.9)..style = PaintingStyle.fill;
    final path = Path();
    final h = width * 0.7;
    path.moveTo(bottomMouth.dx - width, bottomMouth.dy);
    path.cubicTo(
      bottomMouth.dx - width * 0.8, bottomMouth.dy + h * 0.5,
      bottomMouth.dx - width * 0.3, bottomMouth.dy + h,
      bottomMouth.dx, bottomMouth.dy + h * 0.9,
    );
    path.cubicTo(
      bottomMouth.dx + width * 0.3, bottomMouth.dy + h,
      bottomMouth.dx + width * 0.8, bottomMouth.dy + h * 0.5,
      bottomMouth.dx + width, bottomMouth.dy,
    );
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawSmooth(Canvas canvas, Offset center, double rx, double ry) {
    canvas.saveLayer(Rect.largest, Paint());
    final gradPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.18), Colors.transparent],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2));
    canvas.drawOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2), gradPaint);
    canvas.restore();
  }

  void _drawLipstick(Canvas canvas, Offset left, Offset right, Offset bottom) {
    final paint = Paint()..color = Colors.red.withOpacity(0.75)..style = PaintingStyle.fill;
    final w = (right.dx - left.dx);
    final path = Path();
    final midY = (left.dy + right.dy) / 2;
    // الشفة العليا (قوس كيوبيد)
    path.moveTo(left.dx, midY);
    path.cubicTo(left.dx + w * 0.2, midY - w * 0.18, left.dx + w * 0.4, midY - w * 0.22, left.dx + w / 2, midY - w * 0.08);
    path.cubicTo(right.dx - w * 0.4, midY - w * 0.22, right.dx - w * 0.2, midY - w * 0.18, right.dx, midY);
    // الشفة السفلى
    path.cubicTo(right.dx - w * 0.1, bottom.dy + w * 0.08, left.dx + w * 0.1, bottom.dy + w * 0.08, left.dx, midY);
    canvas.drawPath(path, paint);
    // بريق خفيف
    final gloss = Paint()..color = Colors.white.withOpacity(0.25)..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromCenter(center: Offset((left.dx + right.dx) / 2, midY + (bottom.dy - midY) * 0.35), width: w * 0.25, height: w * 0.07), gloss);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.faces != faces || old.filter != filter;
}
