import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../models/meal_model.dart';
import '../models/shopping_item.dart';
import '../helpers/shopping_list_builder.dart';
import '../config/app_theme.dart';

class OverviewScreen extends StatefulWidget {
  final VoidCallback? onGoToHome;

  const OverviewScreen({super.key, this.onGoToHome});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  String? _expandedDay;
  Map<String, String?> _expandedMealType = {};

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ScheduleProvider>().loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 2,
              ),
            );
          }

          final shoppingList = ShoppingListBuilder.build(provider.schedules);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),

                // ── Page Title ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ringkasan jadwal & belanja minggu ini',
                        style: TextStyle(
                          fontFamily: 'SF Pro',
                          fontSize: 13,
                          color: AppTheme.textSecondary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ════════════════════════════════════════════════
                // SECTION 1 — DAILY MEALS CAROUSEL
                // ════════════════════════════════════════════════
                _SectionHeader(
                  icon: Icons.restaurant_rounded,
                  title: 'Jadwal Makan Mingguan',
                  subtitle: 'Ketuk hari untuk melihat menu',
                ),
                const SizedBox(height: 14),

                // Day Carousel — SingleChildScrollView horizontal
                SizedBox(
                  height: 84,
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

                // Expanded Day Panel
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
                          onGoToHome: widget.onGoToHome,
                        ),
                ),

                const SizedBox(height: 32),

                // ════════════════════════════════════════════════
                // SECTION 2 — WEEKLY SHOPPING LIST
                // ════════════════════════════════════════════════
                _SectionHeader(
                  icon: Icons.shopping_cart_rounded,
                  title: 'Daftar Belanja Mingguan',
                  subtitle: shoppingList.isEmpty
                      ? 'Belum ada menu dijadwalkan'
                      : '${shoppingList.length} bahan dari semua menu',
                ),
                const SizedBox(height: 14),

                shoppingList.isEmpty
                    ? _ShoppingListEmpty()
                    : _ShoppingListContent(items: shoppingList),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'SF Pro',
                  fontSize: 11,
                  color: AppTheme.textSecondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shopping List Empty State
// ─────────────────────────────────────────────────────────
class _ShoppingListEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 48,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 12),
          const Text(
            'Daftar belanja masih kosong',
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tambahkan menu ke jadwal untuk\nmelihat ringkasan bahan belanja',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 12,
              color: AppTheme.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shopping List Content
// ─────────────────────────────────────────────────────────
class _ShoppingListContent extends StatefulWidget {
  final Map<String, ShoppingItem> items;
  const _ShoppingListContent({required this.items});

  @override
  State<_ShoppingListContent> createState() => _ShoppingListContentState();
}

class _ShoppingListContentState extends State<_ShoppingListContent> {
  // Track bahan yang sudah dicentang
  final Set<String> _checkedItems = {};

  @override
  Widget build(BuildContext context) {
    final entries = widget.items.entries.toList();
    final unchecked = entries
        .where((e) => !_checkedItems.contains(e.key))
        .toList();
    final checked = entries
        .where((e) => _checkedItems.contains(e.key))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _ProgressBar(
            checked: _checkedItems.length,
            total: entries.length,
          ),
        ),
        const SizedBox(height: 16),

        // Card container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unchecked items
              if (unchecked.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Text(
                    'Perlu dibeli (${unchecked.length})',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...unchecked.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return ShoppingItemTile(
                    itemKey: e.key,
                    item: e.value,
                    isChecked: false,
                    showDivider:
                        idx < unchecked.length - 1 || checked.isNotEmpty,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedItems.add(e.key);
                        } else {
                          _checkedItems.remove(e.key);
                        }
                      });
                    },
                  );
                }),
              ],

              // Checked items
              if (checked.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  child: Text(
                    'Sudah dibeli (${checked.length})',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen.withOpacity(0.6),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...checked.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return ShoppingItemTile(
                    itemKey: e.key,
                    item: e.value,
                    isChecked: true,
                    showDivider: idx < checked.length - 1,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _checkedItems.add(e.key);
                        } else {
                          _checkedItems.remove(e.key);
                        }
                      });
                    },
                  );
                }),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Progress Bar
// ─────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int checked;
  final int total;

  const _ProgressBar({required this.checked, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : checked / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              checked == total && total > 0
                  ? '🎉 Semua bahan sudah dibeli!'
                  : '$checked dari $total bahan sudah dibeli',
              style: const TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontFamily: 'SF Pro',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shopping Item Tile
// ─────────────────────────────────────────────────────────
class ShoppingItemTile extends StatelessWidget {
  final String itemKey;
  final ShoppingItem item;
  final bool isChecked;
  final bool showDivider;
  final ValueChanged<bool?> onChanged;

  const ShoppingItemTile({
    required this.itemKey,
    required this.item,
    required this.isChecked,
    required this.showDivider,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => onChanged(!isChecked),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                // Checkbox custom
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isChecked ? AppTheme.primaryGreen : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked
                          ? AppTheme.primaryGreen
                          : AppTheme.borderColor,
                      width: 1.5,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),

                // Nama bahan
                Expanded(
                  child: Text(
                    item.displayName,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isChecked
                          ? AppTheme.textHint
                          : AppTheme.textPrimary,
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),

                // Jumlah + satuan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isChecked
                        ? AppTheme.borderColor.withOpacity(0.5)
                        : AppTheme.primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.unit.isEmpty
                        ? item.displayQty
                        : '${item.displayQty} ${item.unit}',
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isChecked
                          ? AppTheme.textHint
                          : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tooltip sumber menu (expand on tap)
        if (!isChecked && item.sources.length > 0)
          Padding(
            padding: const EdgeInsets.only(left: 54, right: 18, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 11,
                  color: AppTheme.textHint,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dari: ${item.sources.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF Pro',
                      fontSize: 11,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (showDivider)
          const Divider(
            height: 1,
            indent: 54,
            endIndent: 18,
            color: AppTheme.borderColor,
          ),
      ],
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

  bool get _isToday {
    final today = DateTime.now().weekday;
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
        width: 60,
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
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
  final VoidCallback? onGoToHome;

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
    required this.onGoToHome,
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
              onGoToHome: onGoToHome,
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Meal Type Section
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
  final VoidCallback? onGoToHome;

  const _MealTypeSection({
    required this.mealType,
    required this.label,
    required this.icon,
    required this.color,
    required this.meals,
    required this.isExpanded,
    required this.day,
    required this.onTap,
    required this.onGoToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              children: [
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
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isExpanded
                        ? AppTheme.primaryGreen
                        : AppTheme.textHint,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildMealContent(context),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
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
      return _EmptyMealState(day: day, mealType: mealType, onGoToHome: onGoToHome,);
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
// Empty Meal State
// ─────────────────────────────────────────────────────────
class _EmptyMealState extends StatelessWidget {
  final String day;
  final String mealType;
  final VoidCallback? onGoToHome;

  const _EmptyMealState({
    required this.day,
    required this.mealType,
    this.onGoToHome,
  });

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
          const Icon(
            Icons.restaurant_menu_rounded,
            size: 36,
            color: AppTheme.textHint,
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada menu untuk waktu ini',
            style: TextStyle(
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
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: onGoToHome,
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
// Meal Card
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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: meal.image.isNotEmpty
                ? Image.network(
                    meal.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
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
                    style: const TextStyle(
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
          const Icon(
            Icons.more_vert_rounded,
            size: 18,
            color: AppTheme.textHint,
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
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
