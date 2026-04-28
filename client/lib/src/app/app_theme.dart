import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color backgroundColor = Color(0xFFF6F8FC);
  static const Color sidebarColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF172033);
  static const Color mutedTextColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);

  static const Color softBlueColor = Color(0xFFEFF4FF);
  static const Color softBlue = softBlueColor;

  static const Color lightSurfaceColor = Color(0xFFF8FAFC);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color successColor = Color(0xFF16A34A);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      surface: Colors.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Arial',
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      dividerColor: borderColor,

      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: borderColor),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: mutedTextColor,
          fontSize: 15,
          height: 1.0,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          height: 1.0,
        ),
        prefixIconColor: const Color(0xFF4B5563),
        suffixIconColor: const Color(0xFF4B5563),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: dangerColor,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: dangerColor,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFBFDBFE),
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 0,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          backgroundColor: Colors.white,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 0,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
          side: const BorderSide(
            color: primaryColor,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 0,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          alignment: Alignment.center,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF4B5563),
          minimumSize: const Size(42, 42),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: softBlueColor,
        disabledColor: const Color(0xFFF3F4F6),
        side: const BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF4B5563),
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        secondaryLabelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(lightSurfaceColor),
        headingTextStyle: const TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          height: 1.0,
        ),
        dataTextStyle: const TextStyle(
          color: textColor,
          fontSize: 14,
          height: 1.2,
        ),
        dividerThickness: 1,
        columnSpacing: 28,
        horizontalMargin: 20,
        dataRowMinHeight: 60,
        dataRowMaxHeight: 86,
        headingRowHeight: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.15,
        ),
        contentTextStyle: const TextStyle(
          color: textColor,
          fontSize: 15,
          height: 1.4,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
