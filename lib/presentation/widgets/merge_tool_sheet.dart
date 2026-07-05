import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../controllers/editor_cubit.dart';

class MergeToolSheet extends StatefulWidget {
  final EditorCubit cubit;
  final String lang;
  const MergeToolSheet({super.key, required this.cubit, required this.lang});

  @override
  State<MergeToolSheet> createState() => _MergeToolSheetState();
}

class _MergeToolSheetState extends State<MergeToolSheet> {
  bool _pipZoom = false;

  Future<void> _pickVideo({required bool asPip}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (asPip) {
      widget.cubit.setPipOverlay(PipOverlayModel(
        id: const Uuid().v4(),
        path: path,
        isImage: false,
        animateZoom: _pipZoom,
      ));
    } else {
      widget.cubit.addClip(ClipModel(id: const Uuid().v4(), path: path, duration: 5));
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickImage({required bool asPip}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (asPip) {
      widget.cubit.setPipOverlay(PipOverlayModel(
        id: const Uuid().v4(),
        path: path,
        isImage: true,
        animateZoom: _pipZoom,
      ));
    } else {
      widget.cubit.addClip(ClipModel(id: const Uuid().v4(), path: path, isImage: true, duration: 4));
    }
    if (mounted) Navigator.pop(context);
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
          Text(AppLocalizations.t('tool_merge', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _optionTile(Icons.video_library, AppLocalizations.t('merge_add_video', lang), () => _pickVideo(asPip: false)),
          _optionTile(Icons.image, AppLocalizations.t('merge_add_image', lang), () => _pickImage(asPip: false)),
          const Divider(color: Colors.white24, height: 30),
          Text(AppLocalizations.t('merge_pip', lang), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.t('merge_pip_zoom', lang), style: const TextStyle(color: Colors.white, fontSize: 13)),
            value: _pipZoom,
            activeColor: Colors.amber,
            onChanged: (v) => setState(() => _pipZoom = v),
          ),
          Row(
            children: [
              Expanded(child: _optionTile(Icons.picture_in_picture, AppLocalizations.t('merge_add_video', lang), () => _pickVideo(asPip: true))),
              Expanded(child: _optionTile(Icons.picture_in_picture_alt, AppLocalizations.t('merge_add_image', lang), () => _pickImage(asPip: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _optionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.amber),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: onTap,
    );
  }
}
