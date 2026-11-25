import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class SpColors extends ThemeExtension<SpColors> {
  final Color canvas;
  final Color card;
  final Color raised;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color brand;
  final Color onBrand;
  final Color live;
  final Color win;
  final Color header;
  final Color onHeader;

  final Color accent;
  final Color onAccent;

  final Color glassFill;
  final Color glassBorder;
  final Color glassHighlight;
  final Color glassShadow;

  final Color lensFill;
  final Color lensTint;
  final Color lensBorder;
  final Color lensRim;

  const SpColors({
    required this.canvas,
    required this.card,
    required this.raised,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.brand,
    required this.onBrand,
    required this.live,
    required this.win,
    required this.header,
    required this.onHeader,
    required this.accent,
    required this.onAccent,
    required this.glassFill,
    required this.glassBorder,
    required this.glassHighlight,
    required this.glassShadow,
    required this.lensFill,
    required this.lensTint,
    required this.lensBorder,
    required this.lensRim,
  });

  static const _defaultLight = SpColors(
    canvas: Color(0xFFF2F4F8),
    card: Color(0xFFFFFFFF),
    raised: Color(0xFFF4F6F9),
    line: Color(0xFFE3E7ED),
    ink: Color(0xFF1D1F24),
    muted: Color(0xFF656B77),
    faint: Color(0xFF9CA2AD),
    brand: Color(0xFF3449E8),
    onBrand: Color(0xFFFFFFFF),
    live: Color(0xFFE5243B),
    win: Color(0xFF129A55),
    header: Color(0xFF3449E8),
    onHeader: Color(0xFFFFFFFF),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF2B1D00),
    glassFill: Color(0x9EFFFFFF),
    glassBorder: Color(0xB3FFFFFF),
    glassHighlight: Color(0x80FFFFFF),
    glassShadow: Color(0x1F1D2A55),
    lensFill: Color(0x59FFFFFF),
    lensTint: Color(0x143449E8),
    lensBorder: Color(0x0D000000),
    lensRim: Color(0xFFFFFFFF),
  );

  static const _defaultDark = SpColors(
    canvas: Color(0xFF101116),
    card: Color(0xFF1A1B22),
    raised: Color(0xFF23252E),
    line: Color(0xFF2B2D37),
    ink: Color(0xFFECEDF1),
    muted: Color(0xFF9A9EAA),
    faint: Color(0xFF6A6E7A),
    brand: Color(0xFF7C8CFF),
    onBrand: Color(0xFF0E1030),
    live: Color(0xFFFF5468),
    win: Color(0xFF3CCB7F),
    header: Color(0xFF1A1B22),
    onHeader: Color(0xFFECEDF1),
    accent: Color(0xFFFFC14D),
    onAccent: Color(0xFF2B1D00),
    glassFill: Color(0x992A2C38),
    glassBorder: Color(0x2EFFFFFF),
    glassHighlight: Color(0x14FFFFFF),
    glassShadow: Color(0x73000000),
    lensFill: Color(0x14FFFFFF),
    lensTint: Color(0x267C8CFF),
    lensBorder: Color(0x1FFFFFFF),
    lensRim: Color(0xB3FFFFFF),
  );

  static final SpColors light = switch (_brandOverride) {
    null => _defaultLight,
    final c => _defaultLight._withBrand(
      brand: _legibleOnLight(c),
      onBrand: _onColor(_legibleOnLight(c)),
      header: _legibleOnLight(c),
      lensTint: _legibleOnLight(c).withValues(alpha: 0.08),
    ),
  };

  static final SpColors dark = switch (_brandOverride) {
    null => _defaultDark,
    final c => _defaultDark._withBrand(
      brand: _forDark(c),
      onBrand: _deep(c),
      header: _defaultDark.header,
      lensTint: _forDark(c).withValues(alpha: 0.15),
    ),
  };

  // Opcional al compilar: --dart-define=SP_BRAND=RRGGBB
  static final Color? _brandOverride = _parseBrand(
    const String.fromEnvironment('SP_BRAND'),
  );

  static Color? _parseBrand(String raw) {
    var hex = raw.trim().toUpperCase().replaceFirst('#', '');
    if (hex.startsWith('0X')) hex = hex.substring(2);
    if (hex.length == 6) hex = 'FF$hex';
    final value = hex.length == 8 ? int.tryParse(hex, radix: 16) : null;
    if (raw.isNotEmpty && value == null) {
      debugPrint('SP_BRAND inválido ("$raw"); se usa el azul por defecto.');
    }
    return value == null ? null : Color(value);
  }

  static Color _legibleOnLight(Color c) {
    var hsl = HSLColor.fromColor(c);
    while (hsl.toColor().computeLuminance() > 0.3 && hsl.lightness > 0.2) {
      hsl = hsl.withLightness(hsl.lightness - 0.02);
    }
    return hsl.toColor();
  }

  static Color _forDark(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness(hsl.lightness < 0.72 ? 0.72 : hsl.lightness)
        .withSaturation((hsl.saturation * 1.15).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _deep(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness(0.12).withSaturation(0.55).toColor();
  }

  static Color _onColor(Color c) =>
      ThemeData.estimateBrightnessForColor(c) == Brightness.dark
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF1D1F24);

  SpColors _withBrand({
    required Color brand,
    required Color onBrand,
    required Color header,
    required Color lensTint,
  }) => SpColors(
    canvas: canvas,
    card: card,
    raised: raised,
    line: line,
    ink: ink,
    muted: muted,
    faint: faint,
    brand: brand,
    onBrand: onBrand,
    live: live,
    win: win,
    header: header,
    onHeader: header == this.header ? onHeader : _onColor(header),
    accent: accent,
    onAccent: onAccent,
    glassFill: glassFill,
    glassBorder: glassBorder,
    glassHighlight: glassHighlight,
    glassShadow: glassShadow,
    lensFill: lensFill,
    lensTint: lensTint,
    lensBorder: lensBorder,
    lensRim: lensRim,
  );

  @override
  SpColors copyWith() => this;

  @override
  SpColors lerp(ThemeExtension<SpColors>? other, double t) {
    if (other is! SpColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SpColors(
      canvas: l(canvas, other.canvas),
      card: l(card, other.card),
      raised: l(raised, other.raised),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      faint: l(faint, other.faint),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      live: l(live, other.live),
      win: l(win, other.win),
      header: l(header, other.header),
      onHeader: l(onHeader, other.onHeader),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      glassFill: l(glassFill, other.glassFill),
      glassBorder: l(glassBorder, other.glassBorder),
      glassHighlight: l(glassHighlight, other.glassHighlight),
      glassShadow: l(glassShadow, other.glassShadow),
      lensFill: l(lensFill, other.lensFill),
      lensTint: l(lensTint, other.lensTint),
      lensBorder: l(lensBorder, other.lensBorder),
      lensRim: l(lensRim, other.lensRim),
    );
  }
}

extension SpThemeX on BuildContext {
  SpColors get sp => Theme.of(this).extension<SpColors>()!;
  TextTheme get type => Theme.of(this).textTheme;
}

const List<FontFeature> kTabular = [FontFeature.tabularFigures()];

class AppTheme {
  /// En pruebas se desactiva para no hacer peticiones de red.
  static bool useGoogleFonts = true;

  static TextStyle _font({
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
    Color? color,
    List<FontFeature>? fontFeatures,
  }) {
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
      fontFeatures: fontFeatures,
    );
    return useGoogleFonts ? GoogleFonts.archivo(textStyle: style) : style;
  }

  static ThemeData light() => _build(Brightness.light, SpColors.light);
  static ThemeData dark() => _build(Brightness.dark, SpColors.dark);

  static ThemeData _build(Brightness brightness, SpColors c) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    final text = base.textTheme.copyWith(
      displaySmall: _font(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -1.2,
        color: c.ink,
        fontFeatures: kTabular,
      ),
      headlineSmall: _font(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.4,
        color: c.ink,
      ),
      titleMedium: _font(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.1,
        color: c.ink,
      ),
      titleSmall: _font(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: c.ink,
      ),
      bodyMedium: _font(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: c.ink,
      ),
      bodySmall: _font(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.1,
        color: c.muted,
      ),
      labelMedium: _font(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.15,
        color: c.muted,
      ),
      labelSmall: _font(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0.2,
        color: c.faint,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: c.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.brand,
        brightness: brightness,
        primary: c.brand,
        onPrimary: c.onBrand,
        surface: c.card,
        onSurface: c.ink,
        error: c.live,
      ),
      textTheme: text,
      extensions: [c],
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.header,
        foregroundColor: c.onHeader,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _font(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: c.onHeader,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.card,
        indicatorColor: c.brand.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => _font(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? c.brand : c.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.brand : c.muted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.brand,
        unselectedLabelColor: c.muted,
        indicatorColor: c.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.line,
        labelStyle: _font(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: _font(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: _font(color: c.card, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
