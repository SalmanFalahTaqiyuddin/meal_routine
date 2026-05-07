import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildItem(0, _homeIcon(currentIndex == 0), 'Home'),
              _buildItem(1, _overviewIcon(currentIndex == 1), 'Overview'),
              _buildItem(2, _profileIcon(currentIndex == 2), 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, Widget icon, String label) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive
                    ? AppTheme.primaryGreen
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom icons sesuai desain ──────────────────────────
  Widget _homeIcon(bool active) {
    return Icon(
      active ? Icons.home_rounded : Icons.home_outlined,
      size: 26,
      color: active ? AppTheme.primaryGreen : AppTheme.textSecondary,
    );
  }

  Widget _overviewIcon(bool active) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.article_outlined,
          size: 26,
          color: active ? AppTheme.primaryGreen : AppTheme.textSecondary,
        ),
        Positioned(
          right: -4,
          bottom: -2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: active ? AppTheme.primaryGreen : AppTheme.textSecondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, size: 9, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _profileIcon(bool active) {
    return Icon(
      active ? Icons.person_rounded : Icons.person_outline_rounded,
      size: 26,
      color: active ? AppTheme.primaryGreen : AppTheme.textSecondary,
    );
  }
}
