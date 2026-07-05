import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/transitions_service.dart';
import '../controllers/editor_cubit.dart';

class TransitionsToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String clipId; // الانتقال يُطبَّق قبل هذا المقطع
  final String lang;
  const TransitionsToolSheet({super.key, required this.cubit, required this.clipId, required this.lang});

  @override
  State<TransitionsToolSheet> createState() => _TransitionsToolSheetState();
}

class _TransitionsToolSheetState extends State<TransitionsToolSheet> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.cubit.project.clips.firstWhere((c) => c.id == widget.clipId).transitionId;
  }

  void _apply(String? id) {
    setState(() => _selected = id);
    widget.cubit.updateClip(widget.clipId, (c) => c.transitionId = id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.t('transitions_title', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _chip(null, AppLocalizations.t('transition_none', lang)),
              ...TransitionsService.transitions.map((t) => _chip(t.id, lang == 'ar' ? t.nameAr : t.nameEn)),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: selected ? Colors.amber : Colors.white12, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12)),
      ),
    );
  }
}
