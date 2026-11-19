import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';
import 'sp_widgets.dart';

/// Cristal al estilo iOS: cuerpo casi transparente con un tinte leve de la
/// marca, brillo superior, brillo especular en el borde (más intenso arriba a
/// la izquierda y abajo a la derecha) y una sombra suave.
///
/// Con [backdrop] además desenfoca y satura lo que pasa por detrás. Cuesta un
/// desenfoque por fotograma, así que solo tiene sentido cuando detrás se
/// mueve contenido; sobre un fondo liso se ve igual sin él.
class GlassLens extends StatelessWidget {
  final BorderRadius borderRadius;
  final bool backdrop;

  /// Relleno del cuerpo. Por defecto, `lensFill` con el tinte `lensTint`.
  final Color? fill;
  final double shadowBlur;
  final Widget? child;

  const GlassLens({
    super.key,
    required this.borderRadius,
    this.backdrop = true,
    this.fill,
    this.shadowBlur = 18,
    this.child,
  });

  /// Saturación ×1.8 del fondo: los colores de detrás se ven más vivos a
  /// través del cristal, como en iOS.
  static const _saturate = ColorFilter.matrix([
    1.5662, -0.5148, -0.0514, 0, 0, //
    -0.1838, 1.2552, -0.0714, 0, 0, //
    -0.1838, -0.5148, 1.6986, 0, 0, //
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final body = fill ?? Color.alphaBlend(sp.lensTint, sp.lensFill);
    Color lit(double k) => Color.alphaBlend(
      sp.glassHighlight.withValues(alpha: sp.glassHighlight.a * k),
      body,
    );
    Widget glass = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: sp.lensBorder, width: 0.5),
        // Volumen: la luz entra suave por arriba y rebota un poco abajo, en
        // vez de un brillo plano que lo haría parecer una calcomanía.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lit(0.45), body, body, lit(0.18)],
          stops: const [0, 0.45, 0.75, 1],
        ),
      ),
      child: CustomPaint(
        foregroundPainter: _RimPainter(
          color: sp.lensRim,
          borderRadius: borderRadius,
        ),
        child: child ?? const SizedBox.expand(),
      ),
    );
    if (backdrop) {
      glass = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: _saturate,
            inner: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          ),
          child: glass,
        ),
      );
    }
    if (shadowBlur <= 0) return glass;
    // Sombra difusa y ligera: lo justo para que flote.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: sp.glassShadow.withValues(alpha: sp.glassShadow.a * 0.55),
            blurRadius: shadowBlur * 1.4,
            offset: Offset(0, shadowBlur / 4),
          ),
        ],
      ),
      child: glass,
    );
  }
}

/// Borde especular: un trazo fino y algo difuso cuya intensidad varía en
/// diagonal. Difuminado para que se lea como luz y no como un contorno.
class _RimPainter extends CustomPainter {
  final Color color;
  final BorderRadius borderRadius;

  const _RimPainter({required this.color, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6)
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: color.a * 0.7),
          color.withValues(alpha: color.a * 0.08),
          color.withValues(alpha: color.a * 0.08),
          color.withValues(alpha: color.a * 0.35),
        ],
        stops: const [0, 0.35, 0.7, 1],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(stroke / 2), paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}

/// Botón circular de cristal para las barras superiores, como los de iOS 26.
/// Detrás hay un color liso, así que no desenfoca.
class GlassIconButton extends StatelessWidget {
  final IconData? icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Sustituye al icono (p. ej. un indicador de progreso).
  final Widget? child;

  const GlassIconButton({
    super.key,
    this.icon,
    required this.tooltip,
    required this.onPressed,
    this.child,
  }) : assert(icon != null || child != null);

  static const double _size = 38;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    // Center: las acciones del AppBar estiran a sus hijos en alto; así el
    // botón conserva su forma circular.
    return Center(
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          enabled: onPressed != null,
          label: tooltip,
          excludeSemantics: true,
          child: Pressable(
            onTap: onPressed,
            child: AnimatedOpacity(
              opacity: onPressed == null ? 0.55 : 1,
              duration: const Duration(milliseconds: 160),
              child: SizedBox.square(
                dimension: _size,
                child: GlassLens(
                  borderRadius: BorderRadius.circular(_size / 2),
                  backdrop: false,
                  fill: sp.onHeader.withValues(alpha: 0.12),
                  // Sin sombra: sobre un color liso parecería recortado.
                  shadowBlur: 0,
                  child: Center(
                    child: child ?? Icon(icon, size: 21, color: sp.onHeader),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de pestañas segmentado con una lente de cristal que sigue al
/// dedo: al deslizar entre pestañas se mueve 1:1 con el gesto (lee la
/// animación del `TabController`) y se estira como una gota mientras viaja.
///
/// Usa el `DefaultTabController` más cercano y los colores de `tabBarTheme`.
class GlassTabBar extends StatelessWidget {
  final List<String> labels;

  const GlassTabBar({super.key, required this.labels});

  static const double _inset = 3;

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final controller = DefaultTabController.of(context);
    final tabTheme = TabBarTheme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sp.raised,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / labels.length;
            return AnimatedBuilder(
              animation: controller.animation!,
              builder: (context, _) {
                final pos = controller.animation!.value;
                final frac = (pos - pos.floorToDouble()).abs();
                final stretch = reduceMotion ? 0.0 : math.sin(frac * math.pi);
                final current = pos.round();
                return Stack(
                  children: [
                    Positioned(
                      left: itemWidth * pos,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: Transform.scale(
                        scaleX: 1 + 0.12 * stretch,
                        scaleY: 1 - 0.06 * stretch,
                        child: GlassLens(
                          borderRadius: BorderRadius.circular(999),
                          backdrop: false,
                          shadowBlur: 6,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < labels.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == current,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => controller.animateTo(i),
                                child: Center(
                                  child: Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        (i == current
                                                ? tabTheme.labelStyle
                                                : tabTheme.unselectedLabelStyle)
                                            ?.copyWith(
                                              fontSize: 13,
                                              color: i == current
                                                  ? tabTheme.labelColor
                                                  : tabTheme
                                                        .unselectedLabelColor,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Aviso flotante de cristal. Flota sobre el contenido, así que sí desenfoca
/// lo que tiene detrás.
SnackBar glassSnackBar(
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  return SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    clipBehavior: Clip.none,
    duration: duration,
    content: _GlassSnackContent(message),
  );
}

class _GlassSnackContent extends StatelessWidget {
  final String message;

  const _GlassSnackContent(this.message);

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    return GlassLens(
      borderRadius: BorderRadius.circular(16),
      // Más opaco que la lente de navegación: aquí hay que leer un texto.
      fill: sp.glassFill,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          message,
          style: context.type.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: sp.ink,
          ),
        ),
      ),
    );
  }
}
