import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/firestore_match_repository.dart';
import 'data/match_repository.dart';
import 'features/home/home_shell.dart';
import 'features/setup/firebase_setup_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MatchRepository? repository;
  Object? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    repository = FirestoreMatchRepository();
  } catch (e) {
    initError = e;
  }

  runApp(SetPointApp(repository: repository, initError: initError));
}

class SetPointApp extends StatelessWidget {
  final MatchRepository? repository;
  final Object? initError;

  const SetPointApp({super.key, this.repository, this.initError});

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    return MaterialApp(
      title: 'SetPoint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: repo == null
          ? FirebaseSetupScreen(error: initError)
          : RepositoryScope(repository: repo, child: const HomeShell()),
    );
  }
}