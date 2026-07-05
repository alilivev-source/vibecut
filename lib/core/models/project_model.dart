import 'dart:convert';

/// أبعاد الفيديو
enum VideoRatio { story9x16, landscape16x9, square1x1 }

extension VideoRatioX on VideoRatio {
  String get label {
    switch (this) {
      case VideoRatio.story9x16:
        return '9:16';
      case VideoRatio.landscape16x9:
        return '16:9';
      case VideoRatio.square1x1:
        return '1:1';
    }
  }

  double get aspect {
    switch (this) {
      case VideoRatio.story9x16:
        return 9 / 16;
      case VideoRatio.landscape16x9:
        return 16 / 9;
      case VideoRatio.square1x1:
        return 1;
    }
  }
}

/// مقطع فيديو أو صورة على الخط الزمني
class ClipModel {
  final String id;
  final String path;
  final bool isImage;
  double startTime;
  double duration;
  double speed; // 0.5 -> 3.0
  bool freezeFrame;
  String? filterId; // معرف الفلتر المطبق
  String? transitionId; // الانتقال قبل هذا المقطع

  ClipModel({
    required this.id,
    required this.path,
    this.isImage = false,
    this.startTime = 0,
    required this.duration,
    this.speed = 1.0,
    this.freezeFrame = false,
    this.filterId,
    this.transitionId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'isImage': isImage,
        'startTime': startTime,
        'duration': duration,
        'speed': speed,
        'freezeFrame': freezeFrame,
        'filterId': filterId,
        'transitionId': transitionId,
      };

  factory ClipModel.fromJson(Map<String, dynamic> j) => ClipModel(
        id: j['id'],
        path: j['path'],
        isImage: j['isImage'] ?? false,
        startTime: (j['startTime'] ?? 0).toDouble(),
        duration: (j['duration'] ?? 0).toDouble(),
        speed: (j['speed'] ?? 1.0).toDouble(),
        freezeFrame: j['freezeFrame'] ?? false,
        filterId: j['filterId'],
        transitionId: j['transitionId'],
      );
}

/// نص مُضاف على الفيديو
class TextOverlayModel {
  final String id;
  String text;
  String fontFamily;
  int colorValue;
  bool hasStroke;
  bool hasShadow;
  String animation; // none, fade, slide_up, slide_left, zoom_in, bounce, typewriter, pop, wave
  double x; // نسبة الموضع 0-1
  double y;
  double startTime;
  double duration;

  TextOverlayModel({
    required this.id,
    required this.text,
    this.fontFamily = 'Cairo',
    this.colorValue = 0xFFFFFFFF,
    this.hasStroke = false,
    this.hasShadow = true,
    this.animation = 'none',
    this.x = 0.5,
    this.y = 0.5,
    this.startTime = 0,
    this.duration = 3,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'fontFamily': fontFamily,
        'colorValue': colorValue,
        'hasStroke': hasStroke,
        'hasShadow': hasShadow,
        'animation': animation,
        'x': x,
        'y': y,
        'startTime': startTime,
        'duration': duration,
      };

  factory TextOverlayModel.fromJson(Map<String, dynamic> j) => TextOverlayModel(
        id: j['id'],
        text: j['text'],
        fontFamily: j['fontFamily'] ?? 'Cairo',
        colorValue: j['colorValue'] ?? 0xFFFFFFFF,
        hasStroke: j['hasStroke'] ?? false,
        hasShadow: j['hasShadow'] ?? true,
        animation: j['animation'] ?? 'none',
        x: (j['x'] ?? 0.5).toDouble(),
        y: (j['y'] ?? 0.5).toDouble(),
        startTime: (j['startTime'] ?? 0).toDouble(),
        duration: (j['duration'] ?? 3).toDouble(),
      );
}

/// مسار صوتي إضافي (موسيقى أو تعليق صوتي)
class AudioTrackModel {
  final String id;
  final String path;
  double volume; // 0.0 -> 2.0 (0% -> 200%)
  final bool isVoiceOver;

  AudioTrackModel({
    required this.id,
    required this.path,
    this.volume = 1.0,
    this.isVoiceOver = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'volume': volume,
        'isVoiceOver': isVoiceOver,
      };

  factory AudioTrackModel.fromJson(Map<String, dynamic> j) => AudioTrackModel(
        id: j['id'],
        path: j['path'],
        volume: (j['volume'] ?? 1.0).toDouble(),
        isVoiceOver: j['isVoiceOver'] ?? false,
      );
}

/// نوع الخلفية خلف الفيديو (يظهر عند اختلاف أبعاد المقطع عن أبعاد المشروع)
class BackgroundModel {
  String type; // color, gradient, mosaic
  int colorValue;
  int gradientColor2;

  BackgroundModel({
    this.type = 'color',
    this.colorValue = 0xFF000000,
    this.gradientColor2 = 0xFF6A11CB,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'colorValue': colorValue,
        'gradientColor2': gradientColor2,
      };

  factory BackgroundModel.fromJson(Map<String, dynamic> j) => BackgroundModel(
        type: j['type'] ?? 'color',
        colorValue: j['colorValue'] ?? 0xFF000000,
        gradientColor2: j['gradientColor2'] ?? 0xFF6A11CB,
      );
}

/// طبقة صورة داخل صورة (PiP) - فيديو أو صورة ثانية فوق الفيديو الرئيسي
class PipOverlayModel {
  final String id;
  final String path;
  final bool isImage;
  double x; // نسبة الموضع 0-1 (مركز الطبقة)
  double y;
  double scale; // 0.1 -> 1.0 من حجم الفيديو الرئيسي
  bool animateZoom; // تحريك تكبير تلقائي أثناء التشغيل
  double startTime;
  double duration;

  PipOverlayModel({
    required this.id,
    required this.path,
    this.isImage = false,
    this.x = 0.75,
    this.y = 0.25,
    this.scale = 0.35,
    this.animateZoom = false,
    this.startTime = 0,
    this.duration = 5,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'isImage': isImage,
        'x': x,
        'y': y,
        'scale': scale,
        'animateZoom': animateZoom,
        'startTime': startTime,
        'duration': duration,
      };

  factory PipOverlayModel.fromJson(Map<String, dynamic> j) => PipOverlayModel(
        id: j['id'],
        path: j['path'],
        isImage: j['isImage'] ?? false,
        x: (j['x'] ?? 0.75).toDouble(),
        y: (j['y'] ?? 0.25).toDouble(),
        scale: (j['scale'] ?? 0.35).toDouble(),
        animateZoom: j['animateZoom'] ?? false,
        startTime: (j['startTime'] ?? 0).toDouble(),
        duration: (j['duration'] ?? 5).toDouble(),
      );
}

/// ملصق مُضاف على الفيديو
class StickerOverlayModel {
  final String id;
  final String assetPath;
  double x;
  double y;
  double scale;
  double startTime;
  double duration;

  StickerOverlayModel({
    required this.id,
    required this.assetPath,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 0.25,
    this.startTime = 0,
    this.duration = 3,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'assetPath': assetPath,
        'x': x,
        'y': y,
        'scale': scale,
        'startTime': startTime,
        'duration': duration,
      };

  factory StickerOverlayModel.fromJson(Map<String, dynamic> j) => StickerOverlayModel(
        id: j['id'],
        assetPath: j['assetPath'],
        x: (j['x'] ?? 0.5).toDouble(),
        y: (j['y'] ?? 0.5).toDouble(),
        scale: (j['scale'] ?? 0.25).toDouble(),
        startTime: (j['startTime'] ?? 0).toDouble(),
        duration: (j['duration'] ?? 3).toDouble(),
      );
}

/// المشروع الكامل (المسودة)
class ProjectModel {
  final String id;
  String name;
  VideoRatio ratio;
  List<ClipModel> clips;
  List<TextOverlayModel> texts;
  List<AudioTrackModel> audioTracks;
  List<StickerOverlayModel> stickers;
  PipOverlayModel? pipOverlay;
  BackgroundModel background;
  bool muteOriginal;
  String? thumbnailPath;
  DateTime updatedAt;

  ProjectModel({
    required this.id,
    this.name = 'مشروع بدون اسم',
    this.ratio = VideoRatio.story9x16,
    List<ClipModel>? clips,
    List<TextOverlayModel>? texts,
    List<AudioTrackModel>? audioTracks,
    List<StickerOverlayModel>? stickers,
    this.pipOverlay,
    BackgroundModel? background,
    this.muteOriginal = false,
    this.thumbnailPath,
    DateTime? updatedAt,
  })  : clips = clips ?? [],
        texts = texts ?? [],
        audioTracks = audioTracks ?? [],
        stickers = stickers ?? [],
        background = background ?? BackgroundModel(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalDuration => clips.fold(0.0, (sum, c) => sum + (c.duration / c.speed));

  String toJsonString() => json.encode({
        'id': id,
        'name': name,
        'ratio': ratio.index,
        'clips': clips.map((c) => c.toJson()).toList(),
        'texts': texts.map((t) => t.toJson()).toList(),
        'audioTracks': audioTracks.map((a) => a.toJson()).toList(),
        'stickers': stickers.map((s) => s.toJson()).toList(),
        'pipOverlay': pipOverlay?.toJson(),
        'background': background.toJson(),
        'muteOriginal': muteOriginal,
        'thumbnailPath': thumbnailPath,
        'updatedAt': updatedAt.toIso8601String(),
      });

  factory ProjectModel.fromJsonString(String s) {
    final j = json.decode(s);
    return ProjectModel(
      id: j['id'],
      name: j['name'] ?? 'مشروع بدون اسم',
      ratio: VideoRatio.values[j['ratio'] ?? 0],
      clips: (j['clips'] as List? ?? []).map((c) => ClipModel.fromJson(c)).toList(),
      texts: (j['texts'] as List? ?? []).map((t) => TextOverlayModel.fromJson(t)).toList(),
      audioTracks: (j['audioTracks'] as List? ?? []).map((a) => AudioTrackModel.fromJson(a)).toList(),
      stickers: (j['stickers'] as List? ?? []).map((s) => StickerOverlayModel.fromJson(s)).toList(),
      pipOverlay: j['pipOverlay'] != null ? PipOverlayModel.fromJson(j['pipOverlay']) : null,
      background: j['background'] != null ? BackgroundModel.fromJson(j['background']) : BackgroundModel(),
      muteOriginal: j['muteOriginal'] ?? false,
      thumbnailPath: j['thumbnailPath'],
      updatedAt: j['updatedAt'] != null ? DateTime.parse(j['updatedAt']) : DateTime.now(),
    );
  }

  ProjectModel copy() => ProjectModel.fromJsonString(toJsonString());
}
