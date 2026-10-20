import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          "Módulo 3: Plan de Entrenamiento",
          style: TextStyle(color: AppColors.text, fontSize: 20),
        ),
      ),
    );
  }
}