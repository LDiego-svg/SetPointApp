import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// Pulso de 1 s compartido por todos los [LiveClock], para que los relojes
/// de la pantalla avancen a la vez. Solo corre mientras alguien lo escucha.
class _SecondPulse extends ChangeNotifier {
  Timer? _timer;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      _timer?.cancel();
      _timer = null;
    }
  }
}

final _pulse = _SecondPulse();

/// Reconstruye solo su [builder] una vez por segundo mientras [enabled] (p. ej.
/// el cronómetro del set en marcha), en vez de redibujar la pantalla entera.
///
/// Se pausa cuando no se ve: pestaña oculta o pantalla tapada por otra ruta.
class LiveClock extends StatefulWidget {
  final bool enabled;
  final WidgetBuilder builder;

  const LiveClock({super.key, required this.enabled, required this.builder});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  bool _listening = false;
  bool _visible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _visible = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didUpdateWidget(LiveClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.enabled && _visible;
    if (run && !_listening) {
      _pulse.addListener(_tick);
    } else if (!run && _listening) {
      _pulse.removeListener(_tick);
    }
    _listening = run;
  }

  void _tick() => setState(() {});

  @override
  void dispose() {
    if (_listening) _pulse.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
