import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Se muestra cuando Firebase todavía no está configurado.
class FirebaseSetupScreen extends StatelessWidget {
  final Object? error;

  const FirebaseSetupScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final steps = <(String, String?)>[
      (
        'Crea un proyecto en console.firebase.google.com y activa Cloud Firestore.',
        null,
      ),
      (
        'Instala las herramientas de línea de comandos.',
        'npm install -g firebase-tools\ndart pub global activate flutterfire_cli',
      ),
      (
        'Inicia sesión y conecta este proyecto. Se generará lib/firebase_options.dart.',
        'firebase login\nflutterfire configure',
      ),
      (
        'Vuelve a ejecutar la app y pulsa "Crear partido de ejemplo".',
        'flutter run',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('SetPoint')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            children: [
              Text('Conecta tu base de datos',
                  style: context.type.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Los partidos, equipos y torneos se guardan en Cloud Firestore. '
                'Configúralo una vez y podrás editarlos desde la consola de '
                'Firebase o desde la app.',
                style: context.type.bodyMedium?.copyWith(color: sp.muted),
              ),
              const SizedBox(height: 24),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sp.brand,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: sp.onBrand,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(steps[i].$1,
                                  style: context.type.bodyMedium),
                            ),
                            if (steps[i].$2 != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: sp.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: sp.line),
                                ),
                                child: SelectableText(
                                  steps[i].$2!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    height: 1.5,
                                    color: sp.ink,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text('Detalle técnico', style: context.type.labelMedium),
                const SizedBox(height: 4),
                SelectableText('$error', style: context.type.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
