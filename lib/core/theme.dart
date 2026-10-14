import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF070C16);
  static const Color bgTop = Color(0xFF0C1830);
  static const Color bgBottom = Color(0xFF04070F);
  static const Color glass = Color(0x141A2436);
  static const Color glassBorder = Color(0x337C9CC4);
  static const Color accent = Color(0xFF22D3EE);
  static const Color accent2 = Color(0xFFA855F7); 
  static const Color accent3 = Color(0xFFF472B6); 
  static const Color good = Color(0xFF34D399);
  static const Color warn = Color(0xFFFBBF24);
  static const Color bad = Color(0xFFF87171);
  static const Color textPrimary = Color(0xFFE8F0FB);
  static const Color textSecondary = Color(0xFF93A5C1);
  static const Color textTertiary = Color(0xFF5E6F8C);
  static const Color cardDeep = Color(0xFF0D1526);
  static const Color cardDeep2 = Color(0xFF111C33);
  static const Color shadow = Color(0x66000000);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bg, bgBottom],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF22D3EE), Color(0xFF3B82F6)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x24FFFFFF), Color(0x05FFFFFF)],
  );
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 26;
  static const double xl = 34;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double xxl = 40;
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
      };
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent2,
      surface: AppColors.cardDeep,
      error: AppColors.bad,
      onPrimary: Color(0xFF04121A),
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Vazirmatn',
    ),
    iconTheme: const IconThemeData(color: AppColors.accent),
    splashFactory: InkRipple.splashFactory,
    dividerColor: Colors.white12,
    // ── دکمه‌ها ───────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: const Color(0xFF04121A),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.glassBorder),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    // ── دیالوگ/شیت ────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.cardDeep2,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: AppColors.cardDeep2,
      thumbColor: AppColors.accent,
      overlayColor: Color(0x3322D3EE),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : AppColors.textTertiary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.cardDeep2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.cardDeep,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.accent,
      textColor: AppColors.textPrimary,
    ),
  );
}
