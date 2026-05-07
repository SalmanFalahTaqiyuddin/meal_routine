import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../services/checklist_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  List _weeklyPlan = [];
  List<ChecklistItem> _checklist = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await http.get(Uri.parse('${AppConfig.baseUrl}/weekly-plan'));
      final data = jsonDecode(res.body);
      final checklist = await ChecklistService.getChecklist();
      setState(() {
        _weeklyPlan = data['success'] == true ? data['data'] : [];
        _checklist = checklist;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Weekly Plan',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Text(
                    'Rencana makan sehatmu minggu ini.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ..._weeklyPlan.map((day) => _buildDaySection(day)),

                  const SizedBox(height: 24),
                  const Text(
                    'Bahan yang harus dibeli minggu ini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  ..._checklist.map((item) => _buildChecklistRow(item)),
                ],
              ),
      ),
    );
  }

  Widget _buildDaySection(dynamic day) {
    final meals = day['meals'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${day['day']}, ${day['date']}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: meals.length,
            itemBuilder: (_, i) {
              final meal = meals[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        meal['image'] ?? '',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: AppTheme.borderColor,
                          child: const Icon(Icons.fastfood, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            meal['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${meal['duration']}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildChecklistRow(ChecklistItem item) {
    return Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                await ChecklistService.toggleChecklist(
                  item.id,
                  !item.isChecked,
                );
                setState(() => item.isChecked = !item.isChecked);
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryGreen),
                  color: item.isChecked
                      ? AppTheme.primaryGreen
                      : Colors.transparent,
                ),
                child: item.isChecked
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              item.ingredient,
              style: TextStyle(
                fontSize: 14,
                color: item.isChecked
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
        const Divider(height: 20),
      ],
    );
  }
}
