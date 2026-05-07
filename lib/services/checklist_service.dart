import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ChecklistItem {
  final int id;
  final String ingredient;
  bool isChecked;

  ChecklistItem({
    required this.id,
    required this.ingredient,
    required this.isChecked,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'],
    ingredient: json['ingredient'],
    isChecked: json['is_checked'] ?? false,
  );
}

class ChecklistService {
  static Future<List<ChecklistItem>> getChecklist() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/checklist'));
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => ChecklistItem.fromJson(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<bool> toggleChecklist(int id, bool isChecked) async {
    try {
      final res = await http.put(
        Uri.parse('${AppConfig.baseUrl}/checklist/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'is_checked': isChecked}),
      );
      return jsonDecode(res.body)['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
