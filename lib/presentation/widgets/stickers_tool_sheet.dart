import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../controllers/editor_cubit.dart';

class StickersToolSheet extends StatelessWidget {
  final EditorCubit cubit;
  final String lang;
  final List<String> stickerAssets;
  const StickersToolSheet({super.key, required this.cubit, required this.lang, required this.stickerAssets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 320,
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.t('stickers_title', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: stickerAssets.length,
              itemBuilder: (context, i) {
                final path = stickerAssets[i];
                return GestureDetector(
                  onTap: () {
                    cubit.addSticker(StickerOverlayModel(id: const Uuid().v4(), assetPath: path));
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(path, fit: BoxFit.contain),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
