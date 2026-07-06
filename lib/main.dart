import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/controllers/locale_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.load();
  await MobileAds.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocaleCubit()..loadSaved(),
      child: BlocBuilder<LocaleCubit, String>(
        builder: (context, lang) => MaterialApp(
          title: 'Video Editor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF6A11CB),
            useMaterial3: true,
          ),
          builder: (context, child) => Directionality(
            textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
