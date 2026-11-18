import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Calm Focus" design tokens. Keep in sync with the `:root` block in
/// exam_assistant_admin/src/app/globals.css so web and app stay identical.
abstract final class AppColors {
  static const ink = Color(0xFF0F1A24);
  static const ink2 = Color(0xFF3B4754);
  static const muted = Color(0xFF66717E);
  static const subtle = Color(0xFF98A1AB);
  static const line = Color(0xFFE2E6E1);
  static const lineStrong = Color(0xFFCDD3CC);
  static const paper = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF5F6F2);
  static const sunken = Color(0xFFEFF2EE);
  static const hero = Color(0xFF072E28);
  static const heroSoft = Color(0xFF0B4A40);
  static const brand = Color(0xFF0F6E5E);
  static const brandStrong = Color(0xFF0A5448);
  static const brandSoft = Color(0xFFE4F3EF);
  static const accent = Color(0xFFF4A53A);
  static const accentSoft = Color(0xFFFFF4E2);
  static const success = Color(0xFF2F9B72);
  static const danger = Color(0xFFC2413B);
  static const dangerSoft = Color(0xFFFDF0EF);
}

abstract final class AppRadii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(color: Color(0x0A0F1A24), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F1A24), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

class AppTheme {
  static const Color primaryColor = AppColors.brand;
  static const Color accentColor = AppColors.accent;
  static const Color successColor = AppColors.success;
  static const Color errorColor = AppColors.danger;

  static const String fontFamily = 'Anek Bangla';

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.anekBanglaTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          headlineMedium: GoogleFonts.anekBangla(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
            height: 1.15,
            color: AppColors.ink,
          ),
          titleLarge: GoogleFonts.anekBangla(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: AppColors.ink,
          ),
          titleMedium: GoogleFonts.anekBangla(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          bodyLarge: GoogleFonts.anekBangla(
            fontSize: 16,
            height: 1.5,
            color: AppColors.ink,
          ),
          bodyMedium: GoogleFonts.anekBangla(
            fontSize: 15,
            height: 1.45,
            color: AppColors.ink2,
          ),
          bodySmall: GoogleFonts.anekBangla(
            fontSize: 13,
            height: 1.4,
            color: AppColors.muted,
          ),
          labelLarge: GoogleFonts.anekBangla(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
        titleTextStyle: GoogleFonts.anekBangla(
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
          minimumSize: const Size(double.infinity, 52),
          shape: roundedMd,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: roundedMd,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink2,
          backgroundColor: AppColors.paper,
          minimumSize: const Size(double.infinity, 52),
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
        hintStyle: GoogleFonts.anekBangla(
          fontSize: 16,
          color: AppColors.subtle,
        ),
        labelStyle: GoogleFonts.anekBangla(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: inputBorder(Colors.transparent),
        enabledBorder: inputBorder(Colors.transparent),
        focusedBorder: inputBorder(AppColors.brand),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger),
        errorStyle: GoogleFonts.anekBangla(
          fontSize: 13,
          color: AppColors.danger,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paper,
        selectedColor: AppColors.brandSoft,
        side: const BorderSide(color: AppColors.line),
        labelStyle: GoogleFonts.anekBangla(color: AppColors.ink2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.brandSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.anekBangla(
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
        contentTextStyle: GoogleFonts.anekBangla(
          color: Colors.white,
          fontSize: 14,
        ),
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
