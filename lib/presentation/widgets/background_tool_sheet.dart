import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../controllers/editor_cubit.dart';

class BackgroundToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String lang;
  const BackgroundToolSheet({super.key, required this.cubit, required this.lang});

  @override
  State<BackgroundToolSheet> createState() => _BackgroundToolSheetState();
}

class _BackgroundToolSheetState extends State<BackgroundToolSheet> {
  late String _type;
  late Color _color;

  final List<Color> _palette = const [
    Colors.black, Colors.white, Colors.red, Colors.blue, Colors.green,
    Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.cubit.project.background.type;
    _color = Color(widget.cubit.project.background.colorValue);
  }

  void _apply() {
    widget.cubit.setBackground(BackgroundModel(type: _type, colorValue: _color.value));
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
          Text(AppLocalizations.t('background_title', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              _typeChip('color', AppLocalizations.t('background_color', lang)),
              _typeChip('gradient', AppLocalizations.t('background_gradient', lang)),
              _typeChip('mosaic', AppLocalizations.t('background_mosaic', lang)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final selected = c.value == _color.value;
              return GestureDetector(
                onTap: () => setState(() {
                  _color = c;
                  _apply();
                }),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? Colors.amber : Colors.white24, width: selected ? 3 : 1),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String type, String label) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() {
        _type = type;
        _apply();
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: selected ? Colors.amber : Colors.white12, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12)),
      ),
    );
  }
}
