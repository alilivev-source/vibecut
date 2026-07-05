import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/localization/app_localizations.dart';
import '../controllers/locale_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _watermarkRemoved = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _watermarkRemoved = prefs.getBool('watermark_removed') ?? false);
  }

  Future<void> _toggleWatermark(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watermark_removed', value);
    setState(() => _watermarkRemoved = value);
  }

  void _shareApp(String lang) {
    Share.share(AppLocalizations.t('share_app_message', lang));
  }

  Future<void> _rateApp() async {
    // ضع رابط تطبيقك الحقيقي على Google Play هنا بعد نشره
    final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.example.vibecut_pro');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showHelpDialog(String title, List<String> steps) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: steps
                .map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(
      builder: (context, lang) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(AppLocalizations.t('settings_title', lang)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              _sectionTitle(AppLocalizations.t('language', lang)),
              ListTile(
                leading: const Icon(Icons.language, color: Colors.amber),
                title: Text(lang == 'ar' ? 'العربية' : 'English', style: const TextStyle(color: Colors.white)),
                trailing: Switch(
                  value: lang == 'en',
                  activeColor: Colors.amber,
                  onChanged: (_) => context.read<LocaleCubit>().toggle(),
                ),
              ),
              const Divider(color: Colors.white24),

              _sectionTitle(AppLocalizations.t('help_create_video', lang)),
              ListTile(
                leading: const Icon(Icons.movie_creation_outlined, color: Colors.amber),
                title: Text(AppLocalizations.t('help_create_video', lang), style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                onTap: () => _showHelpDialog(AppLocalizations.t('help_create_video', lang), [
                  AppLocalizations.t('help_create_video_1', lang),
                  AppLocalizations.t('help_create_video_2', lang),
                  AppLocalizations.t('help_create_video_3', lang),
                  AppLocalizations.t('help_create_video_4', lang),
                  AppLocalizations.t('help_create_video_5', lang),
                ]),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share, color: Colors.amber),
                title: Text(AppLocalizations.t('help_export_video', lang), style: const TextStyle(color: Colors.white)),
                trailing: const Icon(Icons.chevron_left, color: Colors.white38),
                onTap: () => _showHelpDialog(AppLocalizations.t('help_export_video', lang), [
                  AppLocalizations.t('help_export_video_1', lang),
                  AppLocalizations.t('help_export_video_2', lang),
                  AppLocalizations.t('help_export_video_3', lang),
                  AppLocalizations.t('help_export_video_4', lang),
                  AppLocalizations.t('help_export_video_5', lang),
                ]),
              ),
              const Divider(color: Colors.white24),

              _sectionTitle(AppLocalizations.t('remove_watermark', lang)),
              SwitchListTile(
                secondary: const Icon(Icons.branding_watermark_outlined, color: Colors.amber),
                title: Text(AppLocalizations.t('remove_watermark', lang), style: const TextStyle(color: Colors.white)),
                subtitle: Text(AppLocalizations.t('remove_watermark_desc', lang),
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                value: _watermarkRemoved,
                activeColor: Colors.amber,
                onChanged: _toggleWatermark,
              ),
              const Divider(color: Colors.white24),

              _sectionTitle(AppLocalizations.t('about_app', lang)),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.amber),
                title: Text(AppLocalizations.t('share_app', lang), style: const TextStyle(color: Colors.white)),
                onTap: () => _shareApp(lang),
              ),
              ListTile(
                leading: const Icon(Icons.star_rate, color: Colors.amber),
                title: Text(AppLocalizations.t('rate_us', lang), style: const TextStyle(color: Colors.white)),
                onTap: _rateApp,
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.amber),
                title: Text(AppLocalizations.t('version', lang), style: const TextStyle(color: Colors.white)),
                trailing: const Text('1.0.0', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
      );
}
