// lib/core/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor:Color(0xFFE6E6E6),

    appBarTheme: AppBarTheme(
      surfaceTintColor: Colors.transparent,
      backgroundColor: const Color(0xff1e1e3f),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Colors.white,
      headerBackgroundColor: const Color(0xff1e1e3f),
      headerForegroundColor: Colors.white,
      todayBackgroundColor: WidgetStateProperty.all(
        const Color.fromARGB(86, 13, 72, 161),
      ),
      todayForegroundColor: WidgetStateProperty.all(Colors.deepPurple),
      dayForegroundColor: WidgetStateProperty.all(Colors.black),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      confirmButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.black),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            inherit: true,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      cancelButtonStyle: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.red),
        textStyle: WidgetStateProperty.all(
          const TextStyle(
            inherit: true,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),

    colorScheme: ColorScheme.light(
      primary: Color(0xFFE6E6E6), // greyish white
      secondary: const Color(0xff1e1e3f),
    ),

    textTheme: GoogleFonts.poppinsTextTheme().copyWith(
      titleLarge: const TextStyle(
        fontSize: 24,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      titleMedium: const TextStyle(
        fontSize: 18,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      titleSmall: const TextStyle(
        fontSize: 14,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      headlineLarge: const TextStyle(
        fontSize: 18,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      headlineMedium: const TextStyle(
        fontSize: 16,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
      headlineSmall: const TextStyle(
        fontSize: 14,
        color: Colors.black,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xff1e1e3f),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor:  const Color(0xff1e1e3f),
      extendedTextStyle: TextStyle(color: Colors.white),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  );
}
