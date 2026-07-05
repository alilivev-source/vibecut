import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/editor_cubit.dart';

class SpeedToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String clipId;
  final String lang;
  const SpeedToolSheet({super.key, required this.cubit, required this.clipId, required this.lang});

  @override
  State<SpeedToolSheet> createState() => _SpeedToolSheetState();
}

class _SpeedToolSheetState extends State<SpeedToolSheet> {
  late double _speed;
  late bool _freeze;

  @override
  void initState() {
    super.initState();
    final clip = widget.cubit.project.clips.firstWhere((c) => c.id == widget.clipId);
    _speed = clip.speed;
    _freeze = clip.freezeFrame;
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
          Text(AppLocalizations.t('speed_title', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('${_speed.toStringAsFixed(1)}x', style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
          Slider(
            value: _speed,
            min: 0.5,
            max: 3.0,
            divisions: 25,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _speed = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.t('speed_freeze', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
            value: _freeze,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _freeze = v),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.cubit.updateClip(widget.clipId, (c) {
                  c.speed = _speed;
                  c.freezeFrame = _freeze;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: Text(AppLocalizations.t('done', lang), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
