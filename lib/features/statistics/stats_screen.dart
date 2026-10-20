import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Módulo 2: Estadísticas del Partido",
          style: TextStyle(color: AppColors.text, fontSize: 20),
        ),
      ),
    );
  }
}