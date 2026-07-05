import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<String> {
  LocaleCubit() : super('ar');

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('lang') ?? 'ar';
    emit(saved);
  }

  Future<void> toggle() async {
    final newLang = state == 'ar' ? 'en' : 'ar';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', newLang);
    emit(newLang);
  }
}
