// lib/config/theme.dart
// configuración visual global — NovaPay Premium Modern Light
import 'package:flutter/material.dart';

class AppTheme {
  // ── Paleta de Colores ─────────────────────────────────────────────────────

  /// Morado real intenso (Acciones principales e inicio de degradados).
  static const Color primary = Color(0xFF6D28D9);

  /// Rosa fucsia vibrante (Final de degradados y acentos).
  static const Color secondary = Color(0xFFEC4899);

  /// Background - Tono plata (gris azulado claro) para aspecto premium.
  static const Color background = Color(0xFFE2E8F0);

  /// Surface - Blanco puro para tarjetas e inputs.
  static const Color surface = Color(0xFFFFFFFF);

  /// Texto principal: Pizarra muy oscuro.
  static const Color textPrimary = Color(0xFF0F172A);

  /// Texto secundario: Gris medio.
  static const Color textSecondary = Color(0xFF64748B);


  /// Bordes y divisores sutiles.
  static const Color border = Color(0xFFCBD5E1);

  // Estados
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF0EA5E9);

  // ── Tema ──────────────────────────────────────────────────────────────────

  static ThemeData get lightModernTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary:                  primary,
        secondary:                secondary,
        error:                    error,
        surface:                  surface,
        onPrimary:                Colors.white,
        onSecondary:              Colors.white,
        onError:                  Colors.white,
        onSurface:                textPrimary,
        outline:                  border,
        // Variantes M3 explícitas — evita colores auto-derivados inesperados
        primaryContainer:         Color(0xFFEDE9FE),   // lila muy claro
        onPrimaryContainer:       Color(0xFF3B0764),   // morado muy oscuro
        secondaryContainer:       Color(0xFFFCE7F3),   // rosa muy claro
        onSecondaryContainer:     Color(0xFF831843),   // rosa muy oscuro
        surfaceContainerHighest:  Color(0xFFF1F5F9),   // gris azulado muy claro
        surfaceContainerHigh:     Color(0xFFE9EFF6),
        surfaceContainer:         Color(0xFFF8FAFC),
      ),

      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        elevation:       0,
        centerTitle:     false,
        backgroundColor: background,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color:      textPrimary,
          fontSize:   20,
          fontWeight: FontWeight.bold,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge:   TextStyle(color: textPrimary,   fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium:  TextStyle(color: textPrimary,   fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall:   TextStyle(color: textPrimary,   fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge:  TextStyle(color: textPrimary,   fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textPrimary,   fontSize: 18, fontWeight: FontWeight.w600),
        headlineSmall:  TextStyle(color: textPrimary,   fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge:      TextStyle(color: textPrimary,   fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium:     TextStyle(color: textPrimary,   fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall:      TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge:     TextStyle(color: textPrimary,   fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium:    TextStyle(color: textPrimary,   fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall:     TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        hintStyle:  const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textPrimary,   fontSize: 14, fontWeight: FontWeight.w500),
        errorStyle: const TextStyle(color: error,         fontSize: 12),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x0D000000), width: 1),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor:   AppTheme.primary.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 12, color: textPrimary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: border),
      ),

      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor:          textPrimary,
        indicatorColor:           primary,
        selectedIconTheme:        IconThemeData(color: Colors.white, size: 28),
        // Color(0xFFCBD5E1) = slate-300: ratio ~5.8:1 sobre #0F172A → pasa WCAG AA
        unselectedIconTheme:      IconThemeData(color: Color(0xFFCBD5E1)),
        selectedLabelTextStyle:   TextStyle(color: Colors.white,         fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFFCBD5E1)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color:     border,
        thickness: 1,
        space:     24,
      ),
    );
  }
}

// GradientButton movido a:
// lib/presentation/widgets/common/gradient_button.dart
