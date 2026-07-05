import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../../core/services/stickers_list.dart';
import '../controllers/editor_cubit.dart';
import '../controllers/locale_cubit.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/text_tool_sheet.dart';
import '../widgets/merge_tool_sheet.dart';
import '../widgets/audio_tool_sheet.dart';
import '../widgets/speed_tool_sheet.dart';
import '../widgets/filters_tool_sheet.dart';
import '../widgets/transitions_tool_sheet.dart';
import '../widgets/stickers_tool_sheet.dart';
import '../widgets/background_tool_sheet.dart';
import 'export_screen.dart';
import 'settings_screen.dart';
import 'face_filters_screen.dart';

class EditorScreen extends StatelessWidget {
  final ProjectModel project;
  const EditorScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditorCubit(project),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView();

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  VideoPlayerController? _controller;
  String? _lastLoadedPath;
  String? _selectedClipId;
  double _zoom = 40; // بكسل لكل ثانية بالخط الزمني
  Timer? _autoSaveTimer;

  // قائمة أسماء ملفات الملصقات المتوفرة كأصول
  static const List<String> stickerAssets = kStickerAssets;

  @override
  void initState() {
    super.initState();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      context.read<EditorCubit>().saveNow();
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _ensureVideoLoaded(ProjectModel project) async {
    if (project.clips.isEmpty) return;
    final clip = project.clips.firstWhere(
      (c) => c.id == _selectedClipId,
      orElse: () => project.clips.last,
    );
    if (clip.isImage) return;
    if (_lastLoadedPath == clip.path) return;

    await _controller?.dispose();
    _controller = VideoPlayerController.file(File(clip.path));
    await _controller!.initialize();
    _lastLoadedPath = clip.path;
    if (mounted) setState(() {});
  }

  void _openSheet(Widget sheet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => sheet,
    );
  }

  String? _currentClipId(ProjectModel project) {
    if (project.clips.isEmpty) return null;
    return _selectedClipId ?? project.clips.last.id;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorCubit>();
    return BlocBuilder<LocaleCubit, String>(
      builder: (context, lang) {
        return BlocBuilder<EditorCubit, EditorState>(
          builder: (context, state) {
            final project = state.project;
            _ensureVideoLoaded(project);

            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: const Color(0xFF1A1A1A),
                leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    tooltip: AppLocalizations.t('settings', lang),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  IconButton(
                    icon: Icon(Icons.undo, color: state.canUndo ? Colors.white : Colors.white24),
                    onPressed: state.canUndo ? cubit.undo : null,
                  ),
                  IconButton(
                    icon: Icon(Icons.redo, color: state.canRedo ? Colors.white : Colors.white24),
                    onPressed: state.canRedo ? cubit.redo : null,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ExportScreen(project: project, lang: lang)));
                    },
                    child: Text(AppLocalizations.t('export_start', lang), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // منطقة المعاينة
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: project.ratio.aspect,
                        child: Container(
                          color: Color(project.background.colorValue),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (_controller != null && _controller!.value.isInitialized)
                                FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                )
                              else
                                const Center(child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 60)),

                              // النصوص المُضافة (معاينة فقط - الحرق الفعلي يحدث بالتصدير)
                              ...project.texts.map((t) => Positioned(
                                    left: t.x * 300 - 50,
                                    top: t.y * 500,
                                    child: Text(
                                      t.text,
                                      style: TextStyle(
                                        color: Color(t.colorValue),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: t.hasShadow ? [const Shadow(color: Colors.black54, blurRadius: 4)] : null,
                                      ),
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // تحكم التشغيل
                  if (_controller != null && _controller!.value.isInitialized)
                    IconButton(
                      icon: Icon(_controller!.value.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 40),
                      onPressed: () => setState(() {
                        _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                      }),
                    ),

                  // الخط الزمني
                  TimelineWidget(
                    project: project,
                    zoom: _zoom,
                    selectedClipId: _currentClipId(project),
                    onSelectClip: (id) => setState(() => _selectedClipId = id),
                    onRemoveClip: (id) => cubit.removeClip(id),
                  ),
                  Slider(
                    value: _zoom,
                    min: 15,
                    max: 100,
                    activeColor: Colors.amber,
                    onChanged: (v) => setState(() => _zoom = v),
                  ),

                  // شريط الأدوات
                  Container(
                    color: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _toolBtn(Icons.text_fields, AppLocalizations.t('tool_text', lang),
                              () => _openSheet(TextToolSheet(cubit: cubit, lang: lang))),
                          _toolBtn(Icons.call_merge, AppLocalizations.t('tool_merge', lang),
                              () => _openSheet(MergeToolSheet(cubit: cubit, lang: lang))),
                          _toolBtn(Icons.audiotrack, AppLocalizations.t('tool_audio', lang),
                              () => _openSheet(AudioToolSheet(cubit: cubit, lang: lang))),
                          _toolBtn(Icons.speed, AppLocalizations.t('tool_speed', lang), () {
                            final id = _currentClipId(project);
                            if (id != null) _openSheet(SpeedToolSheet(cubit: cubit, clipId: id, lang: lang));
                          }),
                          _toolBtn(Icons.filter_vintage, AppLocalizations.t('tool_filters', lang), () {
                            final id = _currentClipId(project);
                            if (id != null) _openSheet(FiltersToolSheet(cubit: cubit, clipId: id, lang: lang));
                          }),
                          _toolBtn(Icons.compare_arrows, AppLocalizations.t('tool_transitions', lang), () {
                            final id = _currentClipId(project);
                            if (id != null) _openSheet(TransitionsToolSheet(cubit: cubit, clipId: id, lang: lang));
                          }),
                          _toolBtn(Icons.emoji_emotions_outlined, AppLocalizations.t('tool_stickers', lang),
                              () => _openSheet(StickersToolSheet(cubit: cubit, lang: lang, stickerAssets: stickerAssets))),
                          _toolBtn(Icons.wallpaper, AppLocalizations.t('tool_background', lang),
                              () => _openSheet(BackgroundToolSheet(cubit: cubit, lang: lang))),
                          _toolBtn(Icons.face_retouching_natural, AppLocalizations.t('tool_face_filters', lang),
                              () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => FaceFiltersScreen(lang: lang)))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _toolBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
