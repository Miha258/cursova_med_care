import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MedCareBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const MedCareBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: const Color(0xFF9CA3AF),
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Головна'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Прийоми'),
        BottomNavigationBarItem(icon: Icon(Icons.people_outlined), activeIcon: Icon(Icons.people), label: 'Пацієнти'),
        BottomNavigationBarItem(icon: Icon(Icons.medication_outlined), activeIcon: Icon(Icons.medication), label: 'Препарати'),
      ],
    );
  }
}
