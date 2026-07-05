import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/controllers/locale_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLocalizations.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocaleCubit()..loadSaved(),
      child: BlocBuilder<LocaleCubit, String>(
        builder: (context, lang) {
          return MaterialApp(
            title: 'Video Editor',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.deepPurple, useMaterial3: true),
            builder: (context, child) => Directionality(
              textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
