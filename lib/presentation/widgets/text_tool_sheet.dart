import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../controllers/editor_cubit.dart';

// 15 خط من Google Fonts (يدعم عربي وإنجليزي)
const List<String> kTextFonts = [
  'Cairo', 'Tajawal', 'Almarai', 'Amiri', 'Lateef', 'Reem Kufi', 'Aref Ruqaa',
  'Roboto', 'Montserrat', 'Poppins', 'Lobster', 'Pacifico', 'Bebas Neue', 'Oswald', 'Playfair Display',
];

const List<String> kTextAnimations = [
  'none', 'fade', 'slide_up', 'slide_left', 'zoom_in', 'bounce', 'typewriter', 'pop', 'wave', 'rotate_in', 'flip',
];

class TextToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String lang;
  const TextToolSheet({super.key, required this.cubit, required this.lang});

  @override
  State<TextToolSheet> createState() => _TextToolSheetState();
}

class _TextToolSheetState extends State<TextToolSheet> {
  final _controller = TextEditingController();
  String _font = 'Cairo';
  Color _color = Colors.white;
  bool _stroke = false;
  bool _shadow = true;
  String _animation = 'none';

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.t('text_add', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                style: TextStyle(color: Colors.white, fontFamily: _font),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white10,
                  hintText: '...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.t('text_font', lang), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: kTextFonts.length,
                  itemBuilder: (context, i) {
                    final f = kTextFonts[i];
                    final selected = f == _font;
                    return GestureDetector(
                      onTap: () => setState(() => _font = f),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? Colors.amber : Colors.white12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(f,
                            style: GoogleFonts.getFont(f, color: selected ? Colors.black : Colors.white, fontSize: 13)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(AppLocalizations.t('text_color', lang), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Colors.white, Colors.black, Colors.red, Colors.orange, Colors.yellow,
                    Colors.green, Colors.blue, Colors.purple, Colors.pink, Colors.amber,
                  ].map((c) {
                    final selected = c.value == _color.value;
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(color: selected ? Colors.amber : Colors.white24, width: selected ? 3 : 1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.t('text_stroke', lang), style: const TextStyle(color: Colors.white, fontSize: 13)),
                      value: _stroke,
                      onChanged: (v) => setState(() => _stroke = v),
                      activeColor: Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.t('text_shadow', lang), style: const TextStyle(color: Colors.white, fontSize: 13)),
                      value: _shadow,
                      onChanged: (v) => setState(() => _shadow = v),
                      activeColor: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.t('text_animation', lang), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kTextAnimations.map((a) {
                  final selected = a == _animation;
                  return GestureDetector(
                    onTap: () => setState(() => _animation = a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.amber : Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(AppLocalizations.t('anim_$a', lang),
                          style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;
                    widget.cubit.addText(TextOverlayModel(
                      id: const Uuid().v4(),
                      text: _controller.text.trim(),
                      fontFamily: _font,
                      colorValue: _color.value,
                      hasStroke: _stroke,
                      hasShadow: _shadow,
                      animation: _animation,
                    ));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(AppLocalizations.t('add', lang), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
