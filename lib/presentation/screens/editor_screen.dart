import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../../core/services/filters_service.dart';
import '../../core/services/stickers_list.dart';
import '../controllers/editor_cubit.dart';
import '../controllers/locale_cubit.dart';
import '../widgets/audio_tool_sheet.dart';
import '../widgets/background_tool_sheet.dart';
import '../widgets/filters_tool_sheet.dart';
import '../widgets/merge_tool_sheet.dart';
import '../widgets/speed_tool_sheet.dart';
import '../widgets/stickers_tool_sheet.dart';
import '../widgets/text_tool_sheet.dart';
import '../widgets/transitions_tool_sheet.dart';
import 'export_screen.dart';
import 'settings_screen.dart';

class EditorScreen extends StatelessWidget {
  final ProjectModel project;
  const EditorScreen({super.key, required this.project});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => EditorCubit(project),
        child: const _EditorView(),
      );
}

class _EditorView extends StatefulWidget {
  const _EditorView();
  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  VideoPlayerController? _vpc;
  String? _lastPath;
  String? _selectedClipId;
  double _zoom = 50.0;
  Timer? _autoSave;
  bool _showControls = true;

  // للنصوص القابلة للسحب
  final Map<String, Offset> _textPositions = {};

  @override
  void initState() {
    super.initState();
    _autoSave = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<EditorCubit>().saveNow();
    });
  }

  @override
  void dispose() {
    _autoSave?.cancel();
    _vpc?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo(String path) async {
    if (_lastPath == path) return;
    await _vpc?.dispose();
    _vpc = VideoPlayerController.file(File(path));
    await _vpc!.initialize();
    _vpc!.addListener(() { if (mounted) setState(() {}); });
    _lastPath = path;
    if (mounted) setState(() {});
  }

  void _addVideo() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.video);
    if (r == null || r.files.single.path == null) return;
    final id = const Uuid().v4();
    context.read<EditorCubit>().addClip(ClipModel(
      id: id, path: r.files.single.path!, duration: 10,
    ));
    setState(() => _selectedClipId = id);
  }

  void _sheet(Widget w) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: context.read<EditorCubit>(),
          child: w,
        ),
      ).then((_) { if (mounted) setState(() {}); });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocBuilder<LocaleCubit, String>(builder: (_, lang) {
      return BlocBuilder<EditorCubit, EditorState>(builder: (_, state) {
        final project = state.project;
        final clip = project.clips.isEmpty ? null
            : project.clips.firstWhere(
                (c) => c.id == (_selectedClipId ?? project.clips.last.id),
                orElse: () => project.clips.last,
              );

        if (clip != null && !clip.isImage) _loadVideo(clip.path);

        final total = _vpc?.value.duration ?? Duration.zero;
        final pos = _vpc?.value.position ?? Duration.zero;
        final progress = total.inMilliseconds > 0
            ? pos.inMilliseconds / total.inMilliseconds : 0.0;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) Navigator.pop(context, true);
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A1A1A),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, true),
              ),
              title: const Text('محرر الفيديو', style: TextStyle(fontSize: 15)),
              titleSpacing: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                ),
                IconButton(
                  icon: Icon(Icons.undo, color: state.canUndo ? Colors.white : Colors.white24, size: 20),
                  onPressed: state.canUndo ? cubit.undo : null,
                ),
                IconButton(
                  icon: Icon(Icons.redo, color: state.canRedo ? Colors.white : Colors.white24, size: 20),
                  onPressed: state.canRedo ? cubit.redo : null,
                ),
                TextButton(
                  onPressed: project.clips.isEmpty ? null : () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => ExportScreen(project: project, lang: lang))),
                  child: Text(AppLocalizations.t('export_start', lang),
                      style: TextStyle(color: project.clips.isEmpty ? Colors.white24 : Colors.amber,
                          fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            body: Column(
              children: [

                // ===== منطقة المعاينة =====
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFF0A0A0A),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [

                          // الخلفية
                          Positioned.fill(child: _BackgroundWidget(bg: project.background)),

                          // مشغل الفيديو
                          if (_vpc != null && _vpc!.value.isInitialized)
                            AspectRatio(
                              aspectRatio: _vpc!.value.aspectRatio,
                              child: VideoPlayer(_vpc!),
                            )
                          else if (project.clips.isEmpty)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: _addVideo,
                                  child: Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, color: Colors.white, size: 40),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text('اضغط لإضافة فيديو أو صورة',
                                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                              ],
                            )
                          else
                            const Icon(Icons.image_outlined, color: Colors.white24, size: 60),

                          // النصوص المتحركة
                          ...project.texts.map((t) {
                            final pos2 = _textPositions[t.id] ?? Offset(
                              MediaQuery.of(context).size.width * t.x,
                              200 * t.y,
                            );
                            return Positioned(
                              left: pos2.dx, top: pos2.dy,
                              child: GestureDetector(
                                onPanUpdate: (d) => setState(() {
                                  _textPositions[t.id] = pos2 + d.delta;
                                }),
                                onLongPress: () {
                                  cubit.removeText(t.id);
                                  _textPositions.remove(t.id);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    t.text,
                                    style: TextStyle(
                                      color: Color(t.colorValue),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      shadows: t.hasShadow
                                          ? [const Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(2, 2))]
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          // عناصر التحكم بالمشغل (داخل المعاينة)
                          if (_vpc != null && _vpc!.value.isInitialized && _showControls)
                            Positioned(
                              bottom: 0, left: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // شريط التقدم
                                    SliderTheme(
                                      data: SliderThemeData(
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                                        trackHeight: 2,
                                        thumbColor: Colors.amber,
                                        activeTrackColor: Colors.amber,
                                        inactiveTrackColor: Colors.white24,
                                        overlayColor: Colors.amber.withOpacity(0.2),
                                      ),
                                      child: Slider(
                                        value: progress.clamp(0.0, 1.0),
                                        onChanged: (v) {
                                          _vpc!.seekTo(total * v);
                                        },
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(_fmt(pos),
                                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                        const Spacer(),
                                        // تراجع 5 ثواني
                                        IconButton(
                                          icon: const Icon(Icons.replay_5, color: Colors.white, size: 22),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            final newPos = pos - const Duration(seconds: 5);
                                            _vpc!.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                                          },
                                        ),
                                        // تشغيل/إيقاف
                                        IconButton(
                                          icon: Icon(
                                            _vpc!.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                                            color: Colors.white, size: 36,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            _vpc!.value.isPlaying ? _vpc!.pause() : _vpc!.play();
                                          },
                                        ),
                                        // تقدم 5 ثواني
                                        IconButton(
                                          icon: const Icon(Icons.forward_5, color: Colors.white, size: 22),
                                          padding: EdgeInsets.zero,
                                          onPressed: () {
                                            final newPos = pos + const Duration(seconds: 5);
                                            _vpc!.seekTo(newPos > total ? total : newPos);
                                          },
                                        ),
                                        const Spacer(),
                                        Text(_fmt(total),
                                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ===== الخط الزمني =====
                Container(
                  height: 88,
                  color: const Color(0xFF141414),
                  child: Row(
                    children: [
                      // زر إضافة مقطع
                      GestureDetector(
                        onTap: _addVideo,
                        child: Container(
                          width: 60, height: 70,
                          margin: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.amber, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Colors.amber, size: 22),
                              Text('إضافة', style: TextStyle(color: Colors.amber, fontSize: 9)),
                            ],
                          ),
                        ),
                      ),
                      // المقاطع
                      Expanded(
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          children: project.clips.map((c) {
                            final w = ((c.duration / c.speed) * _zoom / 10).clamp(50.0, 300.0);
                            final sel = c.id == (_selectedClipId ?? (project.clips.isNotEmpty ? project.clips.last.id : ''));
                            return GestureDetector(
                              onTap: () => setState(() => _selectedClipId = c.id),
                              onLongPress: () {
                                cubit.removeClip(c.id);
                                if (_selectedClipId == c.id) setState(() => _selectedClipId = null);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: w, height: 70,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: c.isImage
                                        ? [const Color(0xFF0D7377), const Color(0xFF14A085)]
                                        : [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sel ? Colors.amber : Colors.transparent, width: 2.5,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(c.isImage ? Icons.image : Icons.movie,
                                        color: Colors.white54, size: 24),
                                    if (c.speed != 1.0)
                                      Positioned(bottom: 4, right: 4,
                                          child: Text('${c.speed}x',
                                              style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold))),
                                    if (c.filterId != null)
                                      const Positioned(top: 4, left: 4,
                                          child: Icon(Icons.auto_awesome, color: Colors.white70, size: 12)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // شريط تكبير الخط الزمني
                Container(
                  color: const Color(0xFF141414),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white38, size: 16),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            trackHeight: 1.5,
                            thumbColor: Colors.white54,
                            activeTrackColor: Colors.white38,
                            inactiveTrackColor: Colors.white12,
                          ),
                          child: Slider(value: _zoom, min: 15, max: 100,
                              onChanged: (v) => setState(() => _zoom = v)),
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white38, size: 16),
                    ],
                  ),
                ),

                // ===== شريط الأدوات =====
                Container(
                  color: const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(children: [
                      _tool(Icons.text_fields, AppLocalizations.t('tool_text', lang), () =>
                          _sheet(TextToolSheet(cubit: cubit, lang: lang))),
                      _tool(Icons.call_merge, AppLocalizations.t('tool_merge', lang), () =>
                          _sheet(MergeToolSheet(cubit: cubit, lang: lang))),
                      _tool(Icons.audiotrack, AppLocalizations.t('tool_audio', lang), () =>
                          _sheet(AudioToolSheet(cubit: cubit, lang: lang))),
                      _tool(Icons.speed, AppLocalizations.t('tool_speed', lang), () {
                        final id = _selectedClipId ?? (project.clips.isNotEmpty ? project.clips.last.id : null);
                        if (id != null) _sheet(SpeedToolSheet(cubit: cubit, clipId: id, lang: lang));
                      }),
                      _tool(Icons.filter_vintage, AppLocalizations.t('tool_filters', lang), () {
                        final id = _selectedClipId ?? (project.clips.isNotEmpty ? project.clips.last.id : null);
                        if (id != null) _sheet(FiltersToolSheet(cubit: cubit, clipId: id, lang: lang));
                      }),
                      _tool(Icons.compare_arrows, AppLocalizations.t('tool_transitions', lang), () {
                        final id = _selectedClipId ?? (project.clips.isNotEmpty ? project.clips.last.id : null);
                        if (id != null) _sheet(TransitionsToolSheet(cubit: cubit, clipId: id, lang: lang));
                      }),
                      _tool(Icons.emoji_emotions_outlined, AppLocalizations.t('tool_stickers', lang), () =>
                          _sheet(StickersToolSheet(cubit: cubit, lang: lang, stickerAssets: kStickerAssets))),
                      _tool(Icons.wallpaper, AppLocalizations.t('tool_background', lang), () =>
                          _sheet(BackgroundToolSheet(cubit: cubit, lang: lang))),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    });
  }

  Widget _tool(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white70, size: 22),
            ),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}

// ويدجت الخلفية
class _BackgroundWidget extends StatelessWidget {
  final BackgroundModel bg;
  const _BackgroundWidget({required this.bg});
  @override
  Widget build(BuildContext context) {
    if (bg.type == 'gradient') {
      return Container(decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(bg.colorValue), Color(bg.gradientColor2)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ));
    }
    if (bg.type == 'mosaic') {
      return CustomPaint(painter: _MosaicPainter(Color(bg.colorValue)));
    }
    return Container(color: Color(bg.colorValue));
  }
}

class _MosaicPainter extends CustomPainter {
  final Color color;
  _MosaicPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const s = 20.0;
    for (double x = 0; x < size.width; x += s) {
      for (double y = 0; y < size.height; y += s) {
        paint.color = ((x ~/ s + y ~/ s) % 2 == 0)
            ? color.withOpacity(0.8) : color.withOpacity(0.5);
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
      }
    }
  }
  @override
  bool shouldRepaint(_MosaicPainter old) => old.color != color;
}

