import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';
import '../services/filters_service.dart';
import '../services/transitions_service.dart';

class ExportResolution {
  final String label;
  final int width;
  final int height;
  const ExportResolution(this.label, this.width, this.height);
}

class FFmpegEngine {
  static const List<ExportResolution> resolutions = [
    ExportResolution('360p', 360, 640),
    ExportResolution('480p', 480, 854),
    ExportResolution('720p HD', 720, 1280),
    ExportResolution('1080p Full HD', 1080, 1920),
    ExportResolution('4K Ultra HD', 2160, 3840),
  ];

  /// بناء أمر FFmpeg الكامل وتنفيذه مع تقرير تقدّم مباشر
  static Future<String?> export({
    required ProjectModel project,
    required int targetWidth,
    required int targetHeight,
    required int fps,
    required void Function(double progress) onProgress,
  }) async {
    if (project.clips.isEmpty) return null;

    // أبعاد فعلية حسب اتجاه المشروع (نبدّل w/h لو المشروع رأسي)
    int w = targetWidth, h = targetHeight;
    if (project.ratio == VideoRatio.story9x16 && targetWidth > targetHeight) {
      final tmp = w;
      w = h;
      h = tmp;
    }

    final dir = await getTemporaryDirectory();
    final outputDir = await getApplicationDocumentsDirectory();
    final outputPath =
        '${outputDir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

    List<String> inputs = [];
    List<String> filterParts = [];

    // ==== 1. تجهيز كل مقطع: تحجيم + سرعة + فلتر ====
    List<String> processedLabels = [];
    for (int i = 0; i < project.clips.length; i++) {
      final clip = project.clips[i];
      inputs.add('-i');
      inputs.add(clip.path);

      String chain = '[$i:v]scale=$w:$h:force_original_aspect_ratio=decrease,'
          'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:color=${_bgColor(project)}';

      // السرعة (تسريع/تبطيء الفيديو بصريًا)
      if (clip.speed != 1.0) {
        chain += ',setpts=PTS/${clip.speed}';
      }

      // الفلتر (LUT حقيقي)
      final filter = FiltersService.byId(clip.filterId);
      if (filter != null) {
        final lutPath = await FiltersService.extractLutToRealPath(filter.lutAsset, filter.id);
        chain += ",lut3d='${lutPath.replaceAll(':', '\\:')}'";
      }

      chain += ',fps=$fps[v$i]';
      filterParts.add(chain);
      processedLabels.add('[v$i]');
    }

    // ==== 2. دمج المقاطع مع الانتقالات (xfade) ====
    String videoOut;
    if (processedLabels.length == 1) {
      videoOut = processedLabels.first;
    } else {
      String chainLabel = processedLabels.first;
      double offset = project.clips.first.duration / project.clips.first.speed - 1.0;
      for (int i = 1; i < processedLabels.length; i++) {
        final clip = project.clips[i];
        final trans = TransitionsService.byId(clip.transitionId)?.id ?? 'fade';
        final nextLabel = i == processedLabels.length - 1 ? '[vout]' : '[vx$i]';
        filterParts.add(
            '$chainLabel${processedLabels[i]}xfade=transition=$trans:duration=0.6:offset=${offset.clamp(0, 999)}$nextLabel');
        chainLabel = nextLabel;
        offset += clip.duration / clip.speed - 0.6;
      }
      videoOut = '[vout]';
    }

    // ==== 3. طبقة PiP (فيديو/صورة ثانية) ====
    String currentVideoLabel = videoOut;
    int nextInputIndex = project.clips.length;
    if (project.pipOverlay != null) {
      final pip = project.pipOverlay!;
      inputs.add('-i');
      inputs.add(pip.path);
      final pipIndex = nextInputIndex;
      nextInputIndex++;
      final pw = (w * pip.scale).round();
      final ph = (h * pip.scale).round();
      final px = ((w - pw) * pip.x).round();
      final py = ((h - ph) * pip.y).round();

      String zoomExpr = pip.animateZoom ? ":x='$px+10*sin(t)':y='$py'" : '';
      filterParts.add('[$pipIndex:v]scale=$pw:$ph[pip]');
      filterParts.add('$currentVideoLabel[pip]overlay=$px:$py$zoomExpr[vpip]');
      currentVideoLabel = '[vpip]';
    }

    // ==== 4. الملصقات ====
    for (final sticker in project.stickers) {
      inputs.add('-i');
      inputs.add(sticker.assetPath);
      final idx = nextInputIndex;
      nextInputIndex++;
      final sw = (w * sticker.scale).round();
      final sx = ((w - sw) * sticker.x).round();
      final sy = ((h * sticker.scale) * 0 + (h - (w * sticker.scale).round()) * sticker.y).round();
      final label = 'sticker$idx';
      filterParts.add('[$idx:v]scale=$sw:-1[$label]');
      final outLabel = '[st$idx]';
      filterParts.add(
          "$currentVideoLabel[$label]overlay=$sx:$sy:enable='between(t,${sticker.startTime},${sticker.startTime + sticker.duration})'$outLabel");
      currentVideoLabel = outLabel;
    }

    // ==== 5. النصوص (drawtext) ====
    for (final text in project.texts) {
      final safeText = text.text.replaceAll("'", "\\'").replaceAll(':', '\\:');
      final color = '0x${text.colorValue.toRadixString(16).padLeft(8, '0').substring(2)}';
      final stroke = text.hasStroke ? ':borderw=3:bordercolor=black' : '';
      final shadow = text.hasShadow ? ':shadowx=2:shadowy=2:shadowcolor=black@0.6' : '';
      final tx = (text.x * w).round();
      final ty = (text.y * h).round();
      final outLabel = '[txt_${text.id}]';

      filterParts.add(
          "$currentVideoLabel"
          "drawtext=text='$safeText':fontcolor=$color:fontsize=48:x=$tx:y=$ty$stroke$shadow:"
          "enable='between(t,${text.startTime},${text.startTime + text.duration})'"
          "$outLabel");
      currentVideoLabel = outLabel;
    }

    // ==== 5.5 العلامة المائية (افتراضية، تُزال من الإعدادات) ====
    final prefs = await SharedPreferences.getInstance();
    final watermarkRemoved = prefs.getBool('watermark_removed') ?? false;
    if (!watermarkRemoved) {
      final outLabel = '[wm_out]';
      filterParts.add(
          "$currentVideoLabel"
          "drawtext=text='Made with Video Editor':fontcolor=white@0.7:fontsize=20:"
          "x=w-tw-15:y=h-th-15:shadowx=1:shadowy=1:shadowcolor=black@0.6"
          "$outLabel");
      currentVideoLabel = outLabel;
    }

    // ==== 6. الصوت (دمج المسارات) ====
    List<String> audioLabels = [];
    if (!project.muteOriginal) {
      for (int i = 0; i < project.clips.length; i++) {
        String a = '[$i:a]';
        if (project.clips[i].speed != 1.0) {
          a += 'atempo=${_clampAtempo(project.clips[i].speed)}';
        }
        audioLabels.add(a);
      }
    }
    for (final track in project.audioTracks) {
      inputs.add('-i');
      inputs.add(track.path);
      final idx = nextInputIndex;
      nextInputIndex++;
      filterParts.add('[$idx:a]volume=${track.volume}[a$idx]');
      audioLabels.add('[a$idx]');
    }

    String audioMapArg = '';
    if (audioLabels.isNotEmpty) {
      if (audioLabels.length == 1) {
        filterParts.add('${audioLabels.first}anull[aout]');
      } else {
        filterParts.add('${audioLabels.join()}amix=inputs=${audioLabels.length}:duration=longest[aout]');
      }
      audioMapArg = '-map [aout]';
    }

    final filterComplex = filterParts.join(';');

    final command = [
      ...inputs,
      '-filter_complex', '"$filterComplex"',
      '-map', currentVideoLabel,
      if (audioMapArg.isNotEmpty) ...audioMapArg.split(' '),
      '-r', '$fps',
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-c:a', 'aac',
      '-y',
      outputPath,
    ].join(' ');

    double totalDurationMs = project.totalDuration * 1000;

    final completer = await FFmpegKit.executeAsync(
      command,
      (session) async {},
      null,
      (Statistics stats) {
        if (totalDurationMs > 0) {
          final progress = (stats.getTime() / totalDurationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      },
    );

    final returnCode = await completer.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    }
    return null;
  }

  static String _bgColor(ProjectModel project) {
    final c = project.background.colorValue;
    return '0x${c.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static String _clampAtempo(double speed) {
    // atempo يدعم فقط 0.5 -> 2.0 لكل فلتر، لسرعات أكبر نسلسل فلترين
    if (speed >= 0.5 && speed <= 2.0) return '$speed';
    if (speed > 2.0) return '2.0,atempo=${(speed / 2.0).toStringAsFixed(2)}';
    return '0.5,atempo=${(speed / 0.5).toStringAsFixed(2)}';
  }
}
