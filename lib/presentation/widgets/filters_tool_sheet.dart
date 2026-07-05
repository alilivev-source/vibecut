import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/filters_service.dart';
import '../controllers/editor_cubit.dart';

class FiltersToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String clipId;
  final String lang;
  const FiltersToolSheet({super.key, required this.cubit, required this.clipId, required this.lang});

  @override
  State<FiltersToolSheet> createState() => _FiltersToolSheetState();
}

class _FiltersToolSheetState extends State<FiltersToolSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.cubit.project.clips.firstWhere((c) => c.id == widget.clipId).filterId;
  }

  void _apply(String? id) {
    setState(() => _selected = id);
    widget.cubit.updateClip(widget.clipId, (c) => c.filterId = id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.t('filters_title', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip(null, AppLocalizations.t('filter_none', lang)),
                ...FiltersService.filters.map((f) => _chip(f.id, lang == 'ar' ? f.nameAr : f.nameEn)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? id, String label) {
    final selected = _selected == id;
    return GestureDetector(
      onTap: () => _apply(id),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(left: 10),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF6A11CB), Color(0xFF2575FC)]),
                shape: BoxShape.circle,
                border: Border.all(color: selected ? Colors.amber : Colors.transparent, width: 3),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: TextStyle(color: selected ? Colors.amber : Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
