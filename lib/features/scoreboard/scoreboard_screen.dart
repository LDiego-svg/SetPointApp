import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/sp_widgets.dart';
import '../../models/match_model.dart';
import '../matches/match_controller.dart';

IconData iconForAction(PointActionType action) {
  switch (action) {
    case PointActionType.attack:
      return Icons.sports_handball_rounded;
    case PointActionType.block:
      return Icons.back_hand_rounded;
    case PointActionType.ace:
      return Icons.gps_fixed_rounded;
    case PointActionType.opponentError:
      return Icons.error_outline_rounded;
  }
}

/// Pestaña "Detalles": registro de puntos, marcador por sets y jugada a jugada.
class ScoreboardScreen extends StatelessWidget {
  final MatchController controller;

  const ScoreboardScreen({super.key, required this.controller});

  MatchModel get _match => controller.match!;

  void _registerPoint(
    BuildContext context,
    bool isLocal,
    PointActionType actionType,
  ) {
    final int previousSet = _match.currentSet;
    controller.addPoint(isLocal, actionType);

    final messenger = ScaffoldMessenger.of(context);
    final endedSetDuration = formatDurationSeconds(
      _match.setsHistory[previousSet - 1].durationSeconds,
    );
    if (_match.isMatchFinished) {
      final winner = _match.localSetsWon > _match.visitSetsWon
          ? _match.localTeamName
          : _match.visitTeamName;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Partido terminado. Gana $winner '
            '${_match.localSetsWon}-${_match.visitSetsWon} '
            '(Set $previousSet: $endedSetDuration)',
          ),
        ),
      );
    } else if (_match.currentSet != previousSet) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Set $previousSet terminado en $endedSetDuration. '
            'Empieza el set ${_match.currentSet}.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _buildScoringCard(context),
                const SizedBox(height: 12),
                _buildSetsTable(context),
                const SizedBox(height: 12),
                _buildPointByPoint(context),
                const SizedBox(height: 12),
                _buildMatchInfoCard(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 1. REGISTRO DE PUNTOS + RELOJ DE SET + DESHACER
  Widget _buildScoringCard(BuildContext context) {
    final sp = context.sp;
    final m = _match;
    return SectionCard(
      title: 'Registrar punto',
      trailing: TextButton.icon(
        onPressed: m.canUndo ? controller.undo : null,
        style: TextButton.styleFrom(
          foregroundColor: sp.brand,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.undo_rounded, size: 18),
        label: const Text(
          'Deshacer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      child: m.isMatchFinished
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'El partido terminó (tiempo total: '
                '${formatDurationSeconds(m.totalMatchElapsedSeconds)}). '
                'Usa Deshacer si necesitas corregir el último punto.',
                style: context.type.bodyMedium?.copyWith(color: sp.muted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (m.isUpcoming) ...[
                  _buildUpcomingBanner(context),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _teamActions(context, isLocal: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _teamActions(context, isLocal: false)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildUpcomingBanner(BuildContext context) {
    final sp = context.sp;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sp.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sp.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partido por empezar',
                  style: TextStyle(
                    color: sp.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  'Inicia el partido para arrancar el reloj del 1.º set.',
                  style: context.type.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: controller.startMatch,
            style: FilledButton.styleFrom(
              backgroundColor: sp.brand,
              foregroundColor: sp.onBrand,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text(
              'Iniciar partido',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamActions(BuildContext context, {required bool isLocal}) {
    final sp = context.sp;
    final m = _match;
    final team = isLocal ? m.localTeam : m.visitTeam;
    final color = Color(team.colorValue);
    final serving = m.isLocalServing == isLocal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            TeamCrest(shortName: team.shortName, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
                style: context.type.titleSmall,
              ),
            ),
            if (serving)
              Tooltip(
                message: 'Tiene el saque',
                child: Icon(Icons.sports_volleyball, size: 15, color: sp.brand),
              ),
          ],
        ),
        const SizedBox(height: 10),
        for (final action in PointActionType.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ActionButton(
              label: action.label,
              icon: iconForAction(action),
              color: color,
              onTap: () => _registerPoint(context, isLocal, action),
            ),
          ),
      ],
    );
  }

  // 2. MARCADOR POR SETS + DURACIÓN POR SET
  Widget _buildSetsTable(BuildContext context) {
    final sp = context.sp;
    final m = _match;
    final head = TextStyle(
      color: sp.faint,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    Widget row(bool isLocal) {
      final team = isLocal ? m.localTeam : m.visitTeam;
      final setsWon = isLocal ? m.localSetsWon : m.visitSetsWon;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            TeamCrest(
              shortName: team.shortName,
              color: Color(team.colorValue),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                team.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final s in m.setsHistory)
              SizedBox(
                width: 42,
                child: Builder(builder: (context) {
                  final played = s.isCompleted ||
                      (s.setNumber == m.currentSet && m.isLive);
                  final score = isLocal ? s.localScore : s.visitScore;
                  final opp = isLocal ? s.visitScore : s.localScore;
                  final current = s.setNumber == m.currentSet && m.isLive;
                  final won = s.isCompleted && score > opp;
                  return Text(
                    played ? '$score' : '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: current ? sp.live : (won ? sp.ink : sp.faint),
                      fontWeight: won || current
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      fontFeatures: kTabular,
                    ),
                  );
                }),
              ),
            SizedBox(
              width: 46,
              child: Text(
                m.isUpcoming ? '–' : '$setsWon',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: m.isUpcoming ? sp.faint : sp.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFeatures: kTabular,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget durationRow() {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Duración',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sp.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final s in m.setsHistory)
              SizedBox(
                width: 42,
                child: Builder(builder: (context) {
                  final current = s.setNumber == m.currentSet && m.isLive;
                  final played = s.isCompleted || current;
                  final secs = m.setElapsedSeconds(s.setNumber);
                  if (!played) return const SizedBox.shrink();
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        formatDurationSeconds(secs),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: current ? sp.live : sp.muted,
                          fontWeight:
                              current ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 11.5,
                          fontFeatures: kTabular,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            SizedBox(
              width: 46,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  m.isUpcoming
                      ? '00:00'
                      : formatDurationSeconds(m.totalMatchElapsedSeconds),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: sp.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    fontFeatures: kTabular,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Marcador por sets',
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: SizedBox()),
              for (var i = 1; i <= 5; i++)
                SizedBox(
                  width: 42,
                  child: Text(
                    '$i',
                    textAlign: TextAlign.center,
                    style: head.copyWith(
                      color: i == m.currentSet && m.isLive ? sp.live : null,
                    ),
                  ),
                ),
              SizedBox(
                width: 46,
                child: Text('Sets', textAlign: TextAlign.right, style: head),
              ),
            ],
          ),
          const SizedBox(height: 4),
          row(true),
          const Divider(),
          row(false),
          const Divider(),
          durationRow(),
        ],
      ),
    );
  }

  // 3. JUGADA A JUGADA
  Widget _buildPointByPoint(BuildContext context) {
    final sp = context.sp;
    final m = _match;
    final recent = m.events.take(12).toList();

    return SectionCard(
      title: 'Jugada a jugada',
      trailing: Text(
        '${m.events.length} jugadas',
        style: context.type.labelMedium,
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: recent.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Aún no hay jugadas. Registra el primer punto arriba.',
                style: context.type.bodyMedium?.copyWith(color: sp.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(),
                  _EventRow(
                    event: recent[i],
                    color: Color(recent[i].isLocalTeam
                        ? m.localTeam.colorValue
                        : m.visitTeam.colorValue),
                  ),
                ],
              ],
            ),
    );
  }

  String _formatDateAndTime(DateTime t) {
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final yyyy = t.year;
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$dd/$mm/$yyyy  •  $h:$m $period';
  }

  // 4. DETALLES DEL PARTIDO (FECHA, SEDE, COMPETICIÓN ESTILO SOFASCORE)
  Widget _buildMatchInfoCard(BuildContext context) {
    final sp = context.sp;
    final m = _match;
    final competitionLabel = [
      m.tournament.name,
      if (m.tournament.category.isNotEmpty) m.tournament.category,
      if (m.stage.isNotEmpty) m.stage,
    ].join(', ');

    Widget infoRow({
      required IconData icon,
      required String label,
      required String value,
      Color? iconColor,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? sp.muted),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.type.labelSmall?.copyWith(
                      color: sp.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: sp.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFeatures: kTabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: sp.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoRow(
            icon: Icons.event_rounded,
            label: 'Fecha y hora',
            value: _formatDateAndTime(m.startTime),
          ),
          if (m.venue.isNotEmpty) ...[
            const Divider(),
            infoRow(
              icon: Icons.location_on_outlined,
              label: 'Lugar',
              value: m.venue,
            ),
          ],
          const Divider(),
          infoRow(
            icon: Icons.emoji_events_outlined,
            iconColor: sp.brand,
            label: 'Competición',
            value: competitionLabel,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return Semantics(
      button: true,
      label: '$label, sumar un punto',
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: sp.raised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sp.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '+1',
                style: TextStyle(
                  color: sp.faint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: kTabular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final MatchEvent event;
  final Color color;

  const _EventRow({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final ev = event;
    final meta = [
      'Set ${ev.setNumber}',
      if (ev.playerTag.isNotEmpty) ev.playerTag,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Text(
              ev.scoreLabel,
              style: TextStyle(
                color: sp.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFeatures: kTabular,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ev.description,
                  style: TextStyle(
                    color: ev.isSetPointWon ? sp.brand : sp.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(meta, style: context.type.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(iconForAction(ev.actionType), size: 16, color: sp.faint),
        ],
      ),
    );
  }
}