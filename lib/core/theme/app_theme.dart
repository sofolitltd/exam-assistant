import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Calm Focus" design tokens. Keep in sync with the `:root` block in
/// exam_assistant_admin/src/app/globals.css so web and app stay identical.
abstract final class AppColors {
  static const ink = Color(0xFF16181D);
  static const ink2 = Color(0xFF4A505B);
  static const muted = Color(0xFF5F6672);
  static const subtle = Color(0xFF8A909A);
  static const line = Color(0xFFE5E5E0);
  static const lineSoft = Color(0xFFEEEEEA);
  static const lineStrong = Color(0xFFCDD0D6);
  static const paper = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF6F6F3);
  static const sunken = Color(0xFFF1F1ED);
  static const segment = Color(0xFFEFEFEA);
  static const hero = Color(0xFF16181D);
  static const heroSoft = Color(0xFF2D323A);
  static const brand = Color(0xFF2446C7);
  static const brandStrong = Color(0xFF1B379E);
  static const brandSoft = Color(0xFFEAEFFD);
  static const brandInk2 = Color(0xFF34427A);
  static const brandLine = Color(0xFFC9D3F5);
  static const accent = Color(0xFFC2410C);
  static const accentSoft = Color(0xFFFFF1E8);
  static const live = Color(0xFFC2410C);
  static const liveInk = Color(0xFFB03A0A);
  static const liveSoft = Color(0xFFFFF1E8);
  static const warmSoft = Color(0xFFFFF8F3);
  static const warmInk = Color(0xFF7A2E0A);
  static const success = Color(0xFF15803D);
  static const successInk = Color(0xFF116132);
  static const successSoft = Color(0xFFECF7EF);
  static const danger = Color(0xFFB91C1C);
  static const dangerSoft = Color(0xFFFDEEEE);
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[];
  static const segment = [
    BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

class AppTheme {
  static const Color primaryColor = AppColors.brand;
  static const Color accentColor = AppColors.accent;
  static const Color successColor = AppColors.success;
  static const Color errorColor = AppColors.danger;

  static String get fontFamily => GoogleFonts.notoSans().fontFamily!;

  /// Latin glyphs come from Noto Sans, Bangla from Noto Sans Bengali.
  static List<String> get fontFallback => [
    GoogleFonts.notoSansBengali().fontFamily!,
  ];

  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.notoSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(fontFamilyFallback: fontFallback);
  }

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.notoSansTextTheme(base.textTheme)
        .apply(
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
          fontFamilyFallback: fontFallback,
        )
        .copyWith(
          headlineMedium: font(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            height: 1.15,
            color: AppColors.ink,
          ),
          titleLarge: font(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
          titleMedium: font(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: font(fontSize: 16, height: 1.5, color: AppColors.ink),
          bodyMedium: font(fontSize: 15, height: 1.45, color: AppColors.ink2),
          bodySmall: font(fontSize: 13, height: 1.4, color: AppColors.muted),
          labelLarge: font(fontSize: 16, fontWeight: FontWeight.w600),
        );

    final roundedMd = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1.5]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        primaryContainer: AppColors.brandSoft,
        onPrimaryContainer: AppColors.brandStrong,
        secondary: AppColors.accent,
        onSecondary: AppColors.ink,
        secondaryContainer: AppColors.accentSoft,
        error: AppColors.danger,
        surface: AppColors.paper,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.lineStrong,
        outlineVariant: AppColors.line,
        surfaceContainerHighest: AppColors.sunken,
      ),
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: font(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.lineStrong,
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: roundedMd,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: roundedMd,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink2,
          backgroundColor: AppColors.paper,
          minimumSize: const Size(double.infinity, 48),
          shape: roundedMd,
          side: const BorderSide(color: AppColors.line),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.sunken,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: font(fontSize: 16, color: AppColors.subtle),
        labelStyle: font(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(AppColors.brand),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger),
        errorStyle: font(fontSize: 13, color: AppColors.danger),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.brandSoft,
        side: const BorderSide(color: AppColors.line),
        labelStyle: font(color: AppColors.ink2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandSoft,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => font(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.brandStrong
                : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.brandStrong
                : AppColors.muted,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.paper,
        indicatorColor: AppColors.brandSoft,
        selectedIconTheme: IconThemeData(color: AppColors.brandStrong),
        unselectedIconTheme: IconThemeData(color: AppColors.muted),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: font(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brand,
      ),
    );
  }
}
