import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/project_model.dart';
import '../../core/ffmpeg/ffmpeg_engine.dart';

class ExportScreen extends StatefulWidget {
  final ProjectModel project;
  final String lang;
  const ExportScreen({super.key, required this.project, required this.lang});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  ExportResolution _resolution = FFmpegEngine.resolutions[2]; // 720p افتراضي
  int _fps = 30;
  bool _exporting = false;
  double _progress = 0;
  String? _resultPath;
  bool _failed = false;

  Future<void> _startExport() async {
    setState(() {
      _exporting = true;
      _progress = 0;
      _failed = false;
      _resultPath = null;
    });

    final result = await FFmpegEngine.export(
      project: widget.project,
      targetWidth: _resolution.width,
      targetHeight: _resolution.height,
      fps: _fps,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      setState(() {
        _exporting = false;
        _resultPath = result;
        _failed = result == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final isHighRes = _resolution.height >= 1920;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(backgroundColor: const Color(0xFF1A1A1A), title: Text(AppLocalizations.t('export_title', lang))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_exporting && _resultPath == null) ...[
              Text(AppLocalizations.t('export_resolution', lang), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: FFmpegEngine.resolutions.map((r) {
                  final selected = r.label == _resolution.label;
                  return GestureDetector(
                    onTap: () => setState(() => _resolution = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: selected ? Colors.amber : Colors.white12, borderRadius: BorderRadius.circular(20)),
                      child: Text(r.label, style: TextStyle(color: selected ? Colors.black : Colors.white)),
                    ),
                  );
                }).toList(),
              ),
              if (isHighRes)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('⚠ ${AppLocalizations.t('export_quality_warning', lang)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
                ),
              const SizedBox(height: 24),
              Text(AppLocalizations.t('export_fps', lang), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: [24, 30, 60].map((f) {
                  final selected = f == _fps;
                  return GestureDetector(
                    onTap: () => setState(() => _fps = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: selected ? Colors.amber : Colors.white12, borderRadius: BorderRadius.circular(20)),
                      child: Text('$f', style: TextStyle(color: selected ? Colors.black : Colors.white)),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startExport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(AppLocalizations.t('export_start', lang), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ] else if (_exporting) ...[
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(value: _progress, strokeWidth: 8, color: Colors.amber, backgroundColor: Colors.white12),
                    ),
                    const SizedBox(height: 16),
                    Text('${(_progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.t('export_progress', lang), style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              const Spacer(),
            ] else ...[
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Icon(_failed ? Icons.error_outline : Icons.check_circle, color: _failed ? Colors.redAccent : Colors.greenAccent, size: 70),
                    const SizedBox(height: 16),
                    Text(
                      _failed ? AppLocalizations.t('export_failed', lang) : AppLocalizations.t('export_done', lang),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(onPressed: _startExport, child: Text(AppLocalizations.t('export_start', lang))),
                    ],
                  ],
                ),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}
