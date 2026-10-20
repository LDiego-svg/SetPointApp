import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Módulo 1: Marcador Digital",
          style: TextStyle(color: AppColors.text, fontSize: 20),
        ),
      ),
    );
  }
}