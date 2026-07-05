import 'package:flutter/material.dart';
import '../../core/models/project_model.dart';

class TimelineWidget extends StatelessWidget {
  final ProjectModel project;
  final String? selectedClipId;
  final double zoom; // بكسل لكل ثانية
  final void Function(String clipId) onSelectClip;
  final void Function(String clipId) onRemoveClip;

  const TimelineWidget({
    super.key,
    required this.project,
    required this.zoom,
    this.selectedClipId,
    required this.onSelectClip,
    required this.onRemoveClip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: const Color(0xFF181818),
      child: project.clips.isEmpty
          ? const Center(
              child: Text('أضف فيديو أو صورة للبدء', style: TextStyle(color: Colors.white38)),
            )
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              children: project.clips.map((clip) {
                final width = ((clip.duration / clip.speed) * zoom).clamp(50.0, 500.0);
                final selected = clip.id == selectedClipId;
                return GestureDetector(
                  onTap: () => onSelectClip(clip.id),
                  onLongPress: () => onRemoveClip(clip.id),
                  child: Container(
                    width: width,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: clip.isImage ? Colors.teal.shade700 : Colors.deepPurple.shade400,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: selected ? Colors.amber : Colors.transparent, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(clip.isImage ? Icons.image : Icons.movie, color: Colors.white70, size: 26),
                        ),
                        if (clip.speed != 1.0)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Text('${clip.speed}x', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        if (clip.filterId != null)
                          const Positioned(
                            top: 4,
                            left: 4,
                            child: Icon(Icons.filter, color: Colors.white70, size: 14),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
