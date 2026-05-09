import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/meal_model.dart';
import '../config/app_theme.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  // Hari yang sedang di-expand
  String? _expandedDay;
  // Meal type yang sedang di-expand per hari
  Map<String, String?> _expandedMealType = {};

  // Label hari pendek untuk tampilan kartu
  static const Map<String, String> _dayLabels = {
    'Sunday': 'Min',
    'Monday': 'Sen',
    'Tuesday': 'Sel',
    'Wednesday': 'Rab',
    'Thursday': 'Kam',
    'Friday': 'Jum',
    'Saturday': 'Sab',
  };

  static const Map<String, String> _dayFullLabels = {
    'Sunday': 'Minggu',
    'Monday': 'Senin',
    'Tuesday': 'Selasa',
    'Wednesday': 'Rabu',
    'Thursday': 'Kamis',
    'Friday': "Jum'at",
    'Saturday': 'Sabtu',
  };

  static const Map<String, IconData> _mealTypeIcons = {
    'Breakfast': Icons.wb_sunny_rounded,
    'Lunch': Icons.light_mode_rounded,
    'Dinner': Icons.nights_stay_rounded,
  };

  static const Map<String, Color> _mealTypeColors = {
    'Breakfast': Color(0xFFF59E0B),
    'Lunch': Color(0xFF10B981),
    'Dinner': Color(0xFF6366F1),
  };

  static const Map<String, String> _mealTypeLabels = {
    'Breakfast': 'Sarapan',
    'Lunch': 'Makan Siang',
    'Dinner': 'Makan Malam',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScheduleProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 2,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Section ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Jadwal Makan Mingguan',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(
                'Ketuk hari untuk melihat menu',
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 12,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Day Carousel ─────────────────────────────────
            SizedBox(
              height: 80,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: ScheduleProvider.days.map((day) {
                    final isSelected = _expandedDay == day;
                    final hasMeals = provider.hasMealsOnDay(day);
                    return _DayCard(
                      day: day,
                      shortLabel: _dayLabels[day]!,
                      isSelected: isSelected,
                      hasMeals: hasMeals,
                      onTap: () {
                        setState(() {
                          if (_expandedDay == day) {
                            _expandedDay = null;
                          } else {
                            _expandedDay = day;
                            _expandedMealType[day] ??= null;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Expanded Day Panel ────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: _expandedDay == null
                  ? const SizedBox.shrink()
                  : _DayExpandedPanel(
                      key: ValueKey(_expandedDay),
                      day: _expandedDay!,
                      dayFullLabel: _dayFullLabels[_expandedDay!]!,
                      provider: provider,
                      expandedMealType: _expandedMealType[_expandedDay],
                      mealTypeIcons: _mealTypeIcons,
                      mealTypeColors: _mealTypeColors,
                      mealTypeLabels: _mealTypeLabels,
                      onMealTypeTap: (mealType) {
                        setState(() {
                          _expandedMealType[_expandedDay!] =
                              _expandedMealType[_expandedDay] == mealType
                                  ? null
                                  : mealType;
                        });
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────
// Day Card Widget
// ─────────────────────────────────────────────────────────
class _DayCard extends StatelessWidget {
  final String day;
  final String shortLabel;
  final bool isSelected;
  final bool hasMeals;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.shortLabel,
    required this.isSelected,
    required this.hasMeals,
    required this.onTap,
  });

  // Cek apakah hari ini
  bool get _isToday {
    final today = DateTime.now().weekday; // 1=Mon ... 7=Sun
    const dayOrder = {
      'Sunday': 7,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
    };
    return dayOrder[day] == today;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 10),
        width: 58,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : _isToday
                  ? AppTheme.primaryGreen.withOpacity(0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryGreen
                : _isToday
                    ? AppTheme.primaryGreen.withOpacity(0.4)
                    : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Dot indicator kalau ada meals
            if (hasMeals)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.lightGreen,
                ),
              )
            else
              const SizedBox(height: 6),
            const SizedBox(height: 4),
            Text(
              shortLabel,
              style: TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? Colors.white
                    : _isToday
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            if (_isToday)
              Text(
                'Hari ini',
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.primaryGreen,
                ),
              )
            else
              const SizedBox(height: 11),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Expanded Day Panel
// ─────────────────────────────────────────────────────────
class _DayExpandedPanel extends StatelessWidget {
  final String day;
  final String dayFullLabel;
  final ScheduleProvider provider;
  final String? expandedMealType;
  final Map<String, IconData> mealTypeIcons;
  final Map<String, Color> mealTypeColors;
  final Map<String, String> mealTypeLabels;
  final ValueChanged<String> onMealTypeTap;

  const _DayExpandedPanel({
    super.key,
    required this.day,
    required this.dayFullLabel,
    required this.provider,
    required this.expandedMealType,
    required this.mealTypeIcons,
    required this.mealTypeColors,
    required this.mealTypeLabels,
    required this.onMealTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Menu $dayFullLabel',
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),

          // Meal Type List
          ...ScheduleProvider.mealTypes.map((mealType) {
            final meals = provider.getMeals(day, mealType);
            final isExpanded = expandedMealType == mealType;
            final color = mealTypeColors[mealType]!;

            return _MealTypeSection(
              mealType: mealType,
              label: mealTypeLabels[mealType]!,
              icon: mealTypeIcons[mealType]!,
              color: color,
              meals: meals,
              isExpanded: isExpanded,
              day: day,
              onTap: () => onMealTypeTap(mealType),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Meal Type Section (Breakfast / Lunch / Dinner)
// ─────────────────────────────────────────────────────────
class _MealTypeSection extends StatelessWidget {
  final String mealType;
  final String label;
  final IconData icon;
  final Color color;
  final List<Meal> meals;
  final bool isExpanded;
  final String day;
  final VoidCallback onTap;

  const _MealTypeSection({
    required this.mealType,
    required this.label,
    required this.icon,
    required this.color,
    required this.meals,
    required this.isExpanded,
    required this.day,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Meal Type Header ──────────────────────────────
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                // Label & count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meals.isEmpty
                            ? 'Belum ada menu'
                            : '${meals.length} menu ditambahkan',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 11,
                          color: meals.isEmpty
                              ? AppTheme.textHint
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isExpanded ? AppTheme.primaryGreen : AppTheme.textHint,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Meal List or Empty State ──────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildMealContent(context),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),

        // Divider between sections
        if (mealType != ScheduleProvider.mealTypes.last)
          const Divider(
            height: 1,
            indent: 18,
            endIndent: 18,
            color: AppTheme.borderColor,
          ),
      ],
    );
  }

  Widget _buildMealContent(BuildContext context) {
    if (meals.isEmpty) {
      return _EmptyMealState(day: day, mealType: mealType);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Column(
        children: meals.map((meal) => _MealCard(meal: meal)).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────────────────
class _EmptyMealState extends StatelessWidget {
  final String day;
  final String mealType;

  const _EmptyMealState({required this.day, required this.mealType});

  static const Map<String, String> _dayLabels = {
    'Sunday': 'Minggu',
    'Monday': 'Senin',
    'Tuesday': 'Selasa',
    'Wednesday': 'Rabu',
    'Thursday': 'Kamis',
    'Friday': "Jum'at",
    'Saturday': 'Sabtu',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_rounded,
            size: 36,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada menu untuk waktu ini',
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan menu ${_dayLabels[day]} dari halaman Home',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 11,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          // Tombol + navigasi ke Home dengan argument hari & meal type
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/home',
                  arguments: {
                    'selectedDay': day,
                    'selectedMealType': mealType,
                  },
                );
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text(
                'Tambah Menu',
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Meal Card Widget
// ─────────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Meal Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: meal.image.isNotEmpty
                ? Image.network(
                    meal.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'SF Pro',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meal.duration,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (meal.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${meal.ingredients.length} bahan',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 11,
                      color: AppTheme.lightGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Kebab menu
          Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: AppTheme.textHint,
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.fastfood_rounded,
        size: 24,
        color: AppTheme.lightGreen,
      ),
    );
  }
}
