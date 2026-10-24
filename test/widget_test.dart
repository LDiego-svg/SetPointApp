import 'package:flutter_test/flutter_test.dart';
import 'package:set_point/core/theme/app_theme.dart';
import 'package:set_point/data/in_memory_match_repository.dart';
import 'package:set_point/main.dart';

void main() {
  setUpAll(() {
    AppTheme.useGoogleFonts = false;
  });

  testWidgets('SetPoint Sofascore flow and Firestore repository persistence', (
    WidgetTester tester,
  ) async {
    final repo = InMemoryMatchRepository();

    await tester.pumpWidget(SetPointApp(repository: repo));
    await tester.pumpAndSettle();

    // Empty database state invites user to seed the sample match
    expect(find.text('Aún no hay partidos'), findsOneWidget);
    await tester.tap(find.text('Crear partido de ejemplo'));
    await tester.pumpAndSettle();

    // Verify MatchesScreen renders tournament & teams from repository
    expect(find.text('Liga Universitaria de Voleibol'), findsOneWidget);
    expect(find.text('Tigres UANL'), findsOneWidget);
    expect(find.text('Borregos MTY'), findsOneWidget);

    // Tap the match row to open MatchDetailScreen
    await tester.tap(find.text('Tigres UANL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify tabs are present
    expect(find.text('Detalles'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Alineación'), findsOneWidget);

    // Score a point for local team and verify repository updated
    expect(repo.matches['partido_demo']!['localPoints'], 0);
    await tester.tap(find.text('Ataque').first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['localPoints'], 1);

    // Undo restores the point in repository
    await tester.tap(find.text('Deshacer'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.matches['partido_demo']!['localPoints'], 0);
  });
}
