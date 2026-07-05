import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../controllers/editor_cubit.dart';

class AudioToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String lang;
  const AudioToolSheet({super.key, required this.cubit, required this.lang});

  @override
  State<AudioToolSheet> createState() => _AudioToolSheetState();
}

class _AudioToolSheetState extends State<AudioToolSheet> {

  Future<void> _pickMusic() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result == null || result.files.single.path == null) return;
    widget.cubit.addAudioTrack(AudioTrackModel(
      id: const Uuid().v4(),
      path: result.files.single.path!,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final project = widget.cubit.project;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.t('tool_audio', lang),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.t('audio_mute', lang),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            value: project.muteOriginal,
            activeColor: Colors.amber,
            onChanged: (v) => widget.cubit.setMuteOriginal(v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note, color: Colors.amber),
            title: Text(AppLocalizations.t('audio_music', lang),
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: _pickMusic,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.mic_off, color: Colors.white38),
            title: const Text('Voice Over (قريبًا / Coming Soon)',
                style: TextStyle(color: Colors.white38, fontSize: 14)),
          ),
          if (project.audioTracks.isNotEmpty) ...[
            const Divider(color: Colors.white24),
            Text(AppLocalizations.t('audio_volume', lang),
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ...project.audioTracks.map((track) => Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: track.volume.clamp(0, 2),
                        min: 0,
                        max: 2,
                        divisions: 20,
                        activeColor: Colors.amber,
                        label: '${(track.volume * 100).round()}%',
                        onChanged: (v) => setState(() => track.volume = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      onPressed: () => setState(() => widget.cubit.removeAudioTrack(track.id)),
                    ),
                  ],
                )),
          ],
        ],
      ),
    );
  }
}
