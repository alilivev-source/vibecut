import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../../core/services/draft_service.dart';
import '../controllers/locale_cubit.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<ProjectModel> drafts = [];
  VideoRatio _selectedRatio = VideoRatio.story9x16;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadDrafts();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final list = await DraftService.loadAll();
    if (mounted) setState(() => drafts = list);
  }

  void _createProject() {
    final project = ProjectModel(id: const Uuid().v4(), ratio: _selectedRatio);
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(project: project)))
        .then((_) => _loadDrafts());
  }

  void _openDraft(ProjectModel p) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => EditorScreen(project: p)))
        .then((_) => _loadDrafts());
  }

  Future<void> _deleteDraft(String id, String lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(AppLocalizations.t('delete', lang), style: const TextStyle(color: Colors.white)),
        content: Text(AppLocalizations.t('delete_confirm', lang), style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.t('cancel', lang), style: const TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.t('delete', lang), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) { await DraftService.delete(id); _loadDrafts(); }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(builder: (context, lang) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: ShaderMask(
            shaderCallback: (b) => const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]).createShader(b),
            child: Text(AppLocalizations.t('app_title', lang),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(lang == 'ar' ? 'EN' : 'ع',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              onPressed: () => context.read<LocaleCubit>().toggle(),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // بطاقة إضافة مشروع جديد
              ScaleTransition(
                scale: _pulse,
                child: GestureDetector(
                  onTap: _createProject,
                  child: Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF6A11CB).withOpacity(0.6), width: 1.5),
                      boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.5), blurRadius: 16)],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 14),
                        Text(AppLocalizations.t('new_project', lang),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.t('choose_ratio', lang),
                            style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // أزرار النسب
              SizedBox(
                height: 82,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _ratioChip(VideoRatio.story9x16, '9:16', Icons.phone_android, lang),
                    _ratioChip(VideoRatio.square1x1, '1:1', Icons.crop_square, lang),
                    _ratioChip(VideoRatio.landscape16x9, '16:9', Icons.tv, lang),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // عنوان المسودات
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                    borderRadius: BorderRadius.circular(2),
                  )),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.t('drafts', lang),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${drafts.length}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                ],
              ),

              const SizedBox(height: 12),

              drafts.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        const Icon(Icons.video_library_outlined, color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        Text(AppLocalizations.t('no_drafts', lang), style: const TextStyle(color: Colors.white38)),
                      ]),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: drafts.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                      itemBuilder: (ctx, i) {
                        final d = drafts[i];
                        return GestureDetector(
                          onTap: () => _openDraft(d),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_draftColor(i).withOpacity(0.2), const Color(0xFF1A1A2E)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _draftColor(i).withOpacity(0.4), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Center(child: Icon(Icons.movie_creation_outlined,
                                      size: 44, color: _draftColor(i).withOpacity(0.8))),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(d.name,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
                                      GestureDetector(
                                        onTap: () => _deleteDraft(d.id, lang),
                                        child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }

  Color _draftColor(int i) {
    const colors = [Color(0xFF6A11CB), Color(0xFF2575FC), Color(0xFFFF6B6B), Color(0xFF4ECDC4), Color(0xFFFFE66D)];
    return colors[i % colors.length];
  }

  Widget _ratioChip(VideoRatio ratio, String label, IconData icon, String lang) {
    final selected = _selectedRatio == ratio;
    return GestureDetector(
      onTap: () => setState(() => _selectedRatio = ratio),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100, height: 78,
        margin: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)])
              : null,
          color: selected ? null : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white24,
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: const Color(0xFF6A11CB).withOpacity(0.4), blurRadius: 12)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
