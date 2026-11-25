import 'package:material_ui/material_ui.dart';

import '../matches/matches_screen.dart';
import '../training/training_screen.dart';
import 'glass_nav_bar.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [MatchesScreen(), TrainingScreen()],
      ),
      bottomNavigationBar: GlassNavBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_volleyball_outlined),
            selectedIcon: Icon(Icons.sports_volleyball),
            label: 'Partidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Entrenamiento',
          ),
        ],
      ),
    );
  }
}
