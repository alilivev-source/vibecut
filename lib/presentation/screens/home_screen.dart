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

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectModel> drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final list = await DraftService.loadAll();
    setState(() => drafts = list);
  }

  void _createProject(VideoRatio ratio, String lang) {
    final project = ProjectModel(id: const Uuid().v4(), ratio: ratio);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
    ).then((_) => _loadDrafts());
  }

  void _openDraft(ProjectModel project) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
    ).then((_) => _loadDrafts());
  }

  Future<void> _deleteDraft(String id, String lang) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.t('delete', lang)),
        content: Text(AppLocalizations.t('delete_confirm', lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.t('cancel', lang))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.t('confirm', lang))),
        ],
      ),
    );
    if (confirm == true) {
      await DraftService.delete(id);
      _loadDrafts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(
      builder: (context, lang) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(AppLocalizations.t('home_title', lang)),
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () => context.read<LocaleCubit>().toggle(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.t('choose_ratio', lang),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ratioCard(VideoRatio.story9x16, AppLocalizations.t('ratio_story', lang), lang),
                    const SizedBox(width: 12),
                    _ratioCard(VideoRatio.landscape16x9, AppLocalizations.t('ratio_landscape', lang), lang),
                    const SizedBox(width: 12),
                    _ratioCard(VideoRatio.square1x1, AppLocalizations.t('ratio_square', lang), lang),
                  ],
                ),
                const SizedBox(height: 28),
                Text(AppLocalizations.t('drafts', lang),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (drafts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(AppLocalizations.t('no_drafts', lang), style: const TextStyle(color: Colors.white54)),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drafts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final d = drafts[index];
                      return GestureDetector(
                        onTap: () => _openDraft(d),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF232323),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Icon(Icons.movie_creation_outlined, size: 40, color: Colors.white24),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(d.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteDraft(d.id, lang),
                                      child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ratioCard(VideoRatio ratio, String label, String lang) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _createProject(ratio, lang),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: ratio.aspect,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white70), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
