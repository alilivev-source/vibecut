import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class FilterDef {
  final String id;
  final String nameAr;
  final String nameEn;
  final String lutAsset; // مسار ملف LUT داخل assets، أو null لـ "بدون فلتر"

  const FilterDef({required this.id, required this.nameAr, required this.nameEn, required this.lutAsset});
}

class FiltersService {
  // 12 فلتر مختارة من ملفات LUT الحقيقية المرفوعة
  static const List<FilterDef> filters = [
    FilterDef(id: 'vibrance', nameAr: 'حيوية', nameEn: 'Vibrance', lutAsset: 'assets/core/filters/luts/01_Color LUTs_Vibrance.cube'),
    FilterDef(id: 'dusty_light', nameAr: 'ضوء ترابي', nameEn: 'Dusty Light', lutAsset: 'assets/core/filters/luts/01_Film LUTs_Dusty Light.cube'),
    FilterDef(id: 'sunrise', nameAr: 'شروق', nameEn: 'Sunrise', lutAsset: 'assets/core/filters/luts/01_Wedding LUTs_Sunrise.cube'),
    FilterDef(id: 'creative_blue', nameAr: 'أزرق إبداعي', nameEn: 'Creative Blue', lutAsset: 'assets/core/filters/luts/02_Color LUTs_Creative Blue.cube'),
    FilterDef(id: 'retro', nameAr: 'ريترو', nameEn: 'Retro', lutAsset: 'assets/core/filters/luts/02_Davinci Resolve LUTs_Retro.cube'),
    FilterDef(id: 'cross_process', nameAr: 'كروس بروسس', nameEn: 'Cross Process', lutAsset: 'assets/core/filters/luts/02_Film Emulation LUTs_Cross Process.cube'),
    FilterDef(id: 'purple_skyline', nameAr: 'أفق بنفسجي', nameEn: 'Purple Skyline', lutAsset: 'assets/core/filters/luts/02_Fujifilm LUTs_Purple Skyline.cube'),
    FilterDef(id: 'cool_mist', nameAr: 'ضباب بارد', nameEn: 'Cool Mist', lutAsset: 'assets/core/filters/luts/02_Mavic Pro LUTs_Cool Mist.cube'),
    FilterDef(id: 'blue_tone', nameAr: 'درجة زرقاء', nameEn: 'Blue Tone', lutAsset: 'assets/core/filters/luts/04_Davinci Resolve LUTs_Blue Tone.cube'),
    FilterDef(id: 'dessert', nameAr: 'صحراوي', nameEn: 'Dessert', lutAsset: 'assets/core/filters/luts/04_Wedding LUTs_Dessert.cube'),
    FilterDef(id: 'matte', nameAr: 'مطفي (Matte)', nameEn: 'Matte', lutAsset: 'assets/core/filters/luts/06_Film Emulation LUTs_Matte.cube'),
    FilterDef(id: 'bw', nameAr: 'أبيض وأسود', nameEn: 'Black & White', lutAsset: 'assets/core/filters/luts/07_Color LUTs_B & W.cube'),
    FilterDef(id: 'saturation', nameAr: 'تشبّع لوني', nameEn: 'Saturation', lutAsset: 'assets/core/filters/luts/08_Wedding LUTs_Saturation.cube'),
    FilterDef(id: 'vintage_city', nameAr: 'مدينة قديمة', nameEn: 'Vintage City', lutAsset: 'assets/core/filters/luts/10_Film Emulation LUTs_Vintage City.cube'),
    FilterDef(id: 'orange_tint', nameAr: 'صبغة برتقالية', nameEn: 'Orange Tint', lutAsset: 'assets/core/filters/luts/5_Teal and Orange LUTs_Orange Tint.cube'),
  ];

  static FilterDef? byId(String? id) {
    if (id == null) return null;
    try {
      return filters.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// نسخ ملف LUT من الأصول إلى مسار حقيقي بالجهاز (مطلوب لأن FFmpeg
  /// لا يستطيع قراءة الملفات مباشرة من AssetBundle الخاص بفلاتر)
  static Future<String> extractLutToRealPath(String assetPath, String filterId) async {
    final dir = await getTemporaryDirectory();
    final outFile = File('${dir.path}/lut_$filterId.cube');
    if (!await outFile.exists()) {
      final data = await rootBundle.load(assetPath);
      await outFile.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    return outFile.path;
  }
}
