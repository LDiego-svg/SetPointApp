import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme/app_theme.dart';
import 'data/firestore_match_repository.dart';
import 'data/match_repository.dart';
import 'features/home/home_shell.dart';
import 'features/setup/firebase_setup_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // La app se dibuja también detrás de la barra de navegación de Android
  // (si no, el sistema rellena esa franja de negro).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _systemBars(Theme.of(context).brightness),
        child: child!,
      ),
      home: repo == null
          ? FirebaseSetupScreen(error: initError)
          : RepositoryScope(repository: repo, child: const HomeShell()),
    );
  }

  /// Barra de navegación del sistema transparente, con iconos que contrastan
  /// con el tema.
  static SystemUiOverlayStyle _systemBars(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}
