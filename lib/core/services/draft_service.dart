import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_model.dart';

class DraftService {
  static const _indexKey = 'draft_ids';

  static Future<List<String>> _getIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_indexKey) ?? [];
  }

  static Future<void> save(ProjectModel project) async {
    final prefs = await SharedPreferences.getInstance();
    project.updatedAt = DateTime.now();
    await prefs.setString('draft_${project.id}', project.toJsonString());

    final ids = await _getIds();
    if (!ids.contains(project.id)) {
      ids.add(project.id);
      await prefs.setStringList(_indexKey, ids);
    }
  }

  static Future<List<ProjectModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _getIds();
    List<ProjectModel> result = [];
    for (final id in ids) {
      final raw = prefs.getString('draft_$id');
      if (raw != null) {
        try {
          result.add(ProjectModel.fromJsonString(raw));
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_$id');
    final ids = await _getIds();
    ids.remove(id);
    await prefs.setStringList(_indexKey, ids);
  }
}
