import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  RewardedAd? _rewardedAd;
  bool _adLoading = false;

  // استخدم معرّف تجريبي الآن - استبدله بمعرّفك الحقيقي من AdMob بعد النشر
  static const _rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadAd();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _watermarkRemoved = prefs.getBool('watermark_removed') ?? false);
  }

  Future<void> _loadAd() async {
    setState(() => _adLoading = true);
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => setState(() { _rewardedAd = ad; _adLoading = false; }),
        onAdFailedToLoad: (err) => setState(() { _rewardedAd = null; _adLoading = false; }),
      ),
    );
  }

  Future<void> _removeWatermarkWithAd() async {
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري تحميل الإعلان، حاول مرة أخرى'), backgroundColor: Colors.orange),
      );
      _loadAd();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) { ad.dispose(); _loadAd(); },
      onAdFailedToShowFullScreenContent: (ad, err) { ad.dispose(); _loadAd(); },
    );
    await _rewardedAd!.show(onUserEarnedReward: (_, reward) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('watermark_removed', true);
      setState(() => _watermarkRemoved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ تمت إزالة العلامة المائية!'), backgroundColor: Colors.green),
        );
      }
    });
  }

  Future<void> _addWatermarkBack() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('watermark_removed', false);
    setState(() => _watermarkRemoved = false);
  }

  void _showHelp(BuildContext context, String title, List<String> steps) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: steps.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(s, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('حسناً', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, String>(builder: (context, lang) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(AppLocalizations.t('settings_title', lang)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [

            _section('🌐 ${AppLocalizations.t('language', lang)}'),
            _card(ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(lang == 'ar' ? 'EN' : 'ع', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
              title: Text(lang == 'ar' ? 'التبديل إلى الإنجليزية' : 'Switch to Arabic',
                  style: const TextStyle(color: Colors.white)),
              trailing: Switch(
                value: lang == 'en',
                activeColor: Colors.amber,
                onChanged: (_) => context.read<LocaleCubit>().toggle(),
              ),
            )),

            _section('📖 ${AppLocalizations.t('help_create_video', lang)}'),
            _card(Column(children: [
              ListTile(
                leading: const Icon(Icons.movie_creation_outlined, color: Colors.amber),
                title: Text(AppLocalizations.t('help_create_video', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () => _showHelp(context, AppLocalizations.t('help_create_video', lang), [
                  AppLocalizations.t('help_create_video_1', lang),
                  AppLocalizations.t('help_create_video_2', lang),
                  AppLocalizations.t('help_create_video_3', lang),
                  AppLocalizations.t('help_create_video_4', lang),
                  AppLocalizations.t('help_create_video_5', lang),
                ]),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.ios_share, color: Colors.amber),
                title: Text(AppLocalizations.t('help_export_video', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () => _showHelp(context, AppLocalizations.t('help_export_video', lang), [
                  AppLocalizations.t('help_export_video_1', lang),
                  AppLocalizations.t('help_export_video_2', lang),
                  AppLocalizations.t('help_export_video_3', lang),
                  AppLocalizations.t('help_export_video_4', lang),
                  AppLocalizations.t('help_export_video_5', lang),
                ]),
              ),
            ])),

            _section('🎬 ${AppLocalizations.t('remove_watermark', lang)}'),
            _card(_watermarkRemoved
                ? ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                    title: const Text('العلامة المائية مُزالة ✅', style: TextStyle(color: Colors.white)),
                    trailing: TextButton(onPressed: _addWatermarkBack,
                        child: const Text('استعادتها', style: TextStyle(color: Colors.redAccent, fontSize: 12))),
                  )
                : ListTile(
                    leading: const Icon(Icons.branding_watermark_outlined, color: Colors.amber),
                    title: Text(AppLocalizations.t('remove_watermark', lang),
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(_adLoading ? 'جارٍ تحميل الإعلان...' : 'شاهد إعلان قصير لإزالتها',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: ElevatedButton(
                      onPressed: _adLoading ? null : _removeWatermarkWithAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: _adLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('إزالة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  )),

            _section('💫 ${AppLocalizations.t('about_app', lang)}'),
            _card(Column(children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.amber),
                title: Text(AppLocalizations.t('share_app', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () => Share.share(AppLocalizations.t('share_app_message', lang)),
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.star_rate, color: Colors.amber),
                title: Text(AppLocalizations.t('rate_us', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                onTap: () async {
                  final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.example.vibecut_pro');
                  if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.amber),
                title: Text(AppLocalizations.t('version', lang), style: const TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Text('1.0.0', style: TextStyle(color: Colors.white38)),
              ),
            ])),
          ],
        ),
      );
    });
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
      );

  Widget _card(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: child,
      );
}
