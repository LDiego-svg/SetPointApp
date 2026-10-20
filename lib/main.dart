import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'features/scoreboard/scoreboard_screen.dart';
import 'features/statistics/stats_screen.dart';
import 'features/training/training_screen.dart';

void main() {
  runApp(const SetPointApp());

}

class SetPointApp extends StatelessWidget {
  const SetPointApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SetPoint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScoreboardScreen(),
    StatsScreen(),
    TrainingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SetPoint',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.scoreboard_outlined),
            activeIcon: Icon(Icons.scoreboard),
            label: 'Marcador',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Entrenamiento',
          ),
        ],
      ),
    );
  }
}