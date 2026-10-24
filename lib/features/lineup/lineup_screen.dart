import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../models/match_model.dart';
import '../matches/match_controller.dart';

/// Pestaña "Alineación": media cancha interactiva con rotación de zonas (1 a 6)
/// y plantilla completa del equipo seleccionado.
class LineupScreen extends StatefulWidget {
  final MatchController controller;

  const LineupScreen({super.key, required this.controller});

  @override
  State<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends State<LineupScreen>
    with AutomaticKeepAliveClientMixin {
  bool _showLocal = true;

  MatchModel get _match => widget.controller.match!;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final m = _match;
    final team = _showLocal ? m.localTeam : m.visitTeam;
    final lineup = _showLocal ? m.localLineup : m.visitLineup;
    final color = Color(team.colorValue);

    return ListView(
      primary: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PillTabs(
                    labels: [m.localTeamName, m.visitTeamName],
                    selected: _showLocal ? 0 : 1,
                    onChanged: (i) => setState(() => _showLocal = i == 0),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCourtCard(context, team, lineup, color),
                const SizedBox(height: 12),
                _buildRosterCard(context, team, lineup, color),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourtCard(
    BuildContext context,
    TeamInfo team,
    List<PlayerPosition> lineup,
    Color color,
  ) {
    final sp = context.sp;
    PlayerPosition at(int zone) {
      return lineup.firstWhere(
        (p) => p.zone == zone,
        orElse: () => PlayerPosition(
          zone: zone,
          dorsal: zone,
          name: 'Zona $zone',
          role: '',
        ),
      );
    }

    return SectionCard(
      title: 'Rotación en cancha',
      trailing: TextButton.icon(
        onPressed: () => widget.controller.rotate(_showLocal),
        style: TextButton.styleFrom(
          foregroundColor: sp.brand,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.rotate_right_rounded, size: 18),
        label: const Text(
          'Rotar +1',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: sp.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sp.line, width: 1.5),
        ),
        child: Column(
          children: [
            // Red superior
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: sp.brand.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border(
                  bottom: BorderSide(color: sp.brand, width: 2),
                ),
              ),
              child: Text(
                'Red · Delanteros (zonas 4, 3, 2)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sp.brand,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CourtSpot(player: at(4), color: color, isServer: false),
                  _CourtSpot(player: at(3), color: color, isServer: false),
                  _CourtSpot(player: at(2), color: color, isServer: false),
                ],
              ),
            ),
            // Línea de 3 metros
            Row(
              children: [
                Expanded(child: Divider(color: sp.line, thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'Línea de 3 m · Zagueros',
                    style: context.type.labelSmall,
                  ),
                ),
                Expanded(child: Divider(color: sp.line, thickness: 1)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CourtSpot(player: at(5), color: color, isServer: false),
                  _CourtSpot(player: at(6), color: color, isServer: false),
                  _CourtSpot(player: at(1), color: color, isServer: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard(
    BuildContext context,
    TeamInfo team,
    List<PlayerPosition> lineup,
    Color color,
  ) {
    final sp = context.sp;
    final sorted = List<PlayerPosition>.from(lineup)
      ..sort((a, b) => a.zone.compareTo(b.zone));

    return SectionCard(
      title: 'Jugadores en cancha',
      trailing: Text('${sorted.length} titulares', style: context.type.labelMedium),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        children: [
          for (var i = 0; i < sorted.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${sorted[i].dorsal}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFeatures: kTabular,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sorted[i].name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (sorted[i].role.isNotEmpty)
                          Text(sorted[i].role, style: context.type.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sorted[i].zone == 1
                          ? sp.brand.withValues(alpha: 0.12)
                          : sp.raised,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sorted[i].zone == 1
                          ? 'Zona 1 · Saque'
                          : 'Zona ${sorted[i].zone}',
                      style: TextStyle(
                        color: sorted[i].zone == 1 ? sp.brand : sp.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CourtSpot extends StatelessWidget {
  final PlayerPosition player;
  final Color color;
  final bool isServer;

  const _CourtSpot({
    required this.player,
    required this.color,
    required this.isServer,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : const Color(0xFF15161A);

    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isServer ? 'Z${player.zone} · Saque' : 'Zona ${player.zone}',
            style: TextStyle(
              color: isServer ? sp.brand : sp.faint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isServer ? sp.brand : Colors.black12,
                width: isServer ? 2.5 : 1,
              ),
            ),
            child: Text(
              '#${player.dorsal}',
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
                fontFeatures: kTabular,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sp.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (player.role.isNotEmpty)
            Text(
              player.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.labelSmall,
            ),
        ],
      ),
    );
  }
}
