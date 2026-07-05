class TransitionDef {
  final String id; // اسم فلتر xfade في FFmpeg
  final String nameAr;
  final String nameEn;

  const TransitionDef({required this.id, required this.nameAr, required this.nameEn});
}

class TransitionsService {
  // 10 انتقالات باستخدام فلتر xfade المدمج في FFmpeg (بدون أي ملفات خارجية)
  static const List<TransitionDef> transitions = [
    TransitionDef(id: 'fade', nameAr: 'تلاشي', nameEn: 'Fade'),
    TransitionDef(id: 'wipeleft', nameAr: 'مسح لليسار', nameEn: 'Wipe Left'),
    TransitionDef(id: 'wiperight', nameAr: 'مسح لليمين', nameEn: 'Wipe Right'),
    TransitionDef(id: 'slideup', nameAr: 'انزلاق لأعلى', nameEn: 'Slide Up'),
    TransitionDef(id: 'slidedown', nameAr: 'انزلاق لأسفل', nameEn: 'Slide Down'),
    TransitionDef(id: 'circleopen', nameAr: 'دائرة تفتح', nameEn: 'Circle Open'),
    TransitionDef(id: 'circleclose', nameAr: 'دائرة تُغلق', nameEn: 'Circle Close'),
    TransitionDef(id: 'pixelize', nameAr: 'تبكسل', nameEn: 'Pixelize'),
    TransitionDef(id: 'dissolve', nameAr: 'ذوبان', nameEn: 'Dissolve'),
    TransitionDef(id: 'zoomin', nameAr: 'تقريب', nameEn: 'Zoom In'),
    TransitionDef(id: 'wipeup', nameAr: 'مسح لأعلى', nameEn: 'Wipe Up'),
    TransitionDef(id: 'wipedown', nameAr: 'مسح لأسفل', nameEn: 'Wipe Down'),
    TransitionDef(id: 'smoothleft', nameAr: 'انسيابي لليسار', nameEn: 'Smooth Left'),
    TransitionDef(id: 'smoothright', nameAr: 'انسيابي لليمين', nameEn: 'Smooth Right'),
    TransitionDef(id: 'circlecrop', nameAr: 'قص دائري', nameEn: 'Circle Crop'),
    TransitionDef(id: 'rectcrop', nameAr: 'قص مستطيل', nameEn: 'Rect Crop'),
    TransitionDef(id: 'radial', nameAr: 'إشعاعي', nameEn: 'Radial'),
    TransitionDef(id: 'vertopen', nameAr: 'فتح عمودي', nameEn: 'Vertical Open'),
    TransitionDef(id: 'horzopen', nameAr: 'فتح أفقي', nameEn: 'Horizontal Open'),
    TransitionDef(id: 'diagtl', nameAr: 'قطري علوي', nameEn: 'Diagonal TL'),
    TransitionDef(id: 'hlslice', nameAr: 'شرائح أفقية', nameEn: 'H Slice'),
    TransitionDef(id: 'vuslice', nameAr: 'شرائح عمودية', nameEn: 'V Slice'),
    TransitionDef(id: 'hblur', nameAr: 'ضبابية أفقية', nameEn: 'H Blur'),
    TransitionDef(id: 'coverleft', nameAr: 'تغطية لليسار', nameEn: 'Cover Left'),
    TransitionDef(id: 'revealright', nameAr: 'كشف لليمين', nameEn: 'Reveal Right'),
  ];

  static TransitionDef? byId(String? id) {
    if (id == null) return null;
    try {
      return transitions.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
