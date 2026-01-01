import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class BlockPayTheme {
 // Brand Colors
 static const Color electricGreen = Color(0xFF00E676);
 static const Color obsidianBlack = Color(0xFF121212);
 static const Color surfaceGrey = Color(0xFF1E1E1E);
 static const Color subtleGrey = Color(0xFF9E9E9E);
 static const Color offWhite = Color(0xFFF8F9FA);


 // Dark Theme Definition
 static ThemeData get darkTheme {
   return ThemeData(
     useMaterial3: true,
     brightness: Brightness.dark,
     scaffoldBackgroundColor: obsidianBlack,
     colorScheme: const ColorScheme.dark(
       primary: electricGreen,
       onPrimary: Colors.black,
       secondary: electricGreen,
       surface: surfaceGrey,
       onSurface: Colors.white,
     ),
     textTheme: GoogleFonts.plusJakartaSansTextTheme(
       const TextTheme(
         displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
         headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
         bodyLarge: TextStyle(color: Colors.white),
         bodyMedium: TextStyle(color: subtleGrey),
       ),
     ),
     appBarTheme: _sharedAppBar(obsidianBlack, Colors.white),
     cardTheme: _sharedCardTheme(surfaceGrey, electricGreen.withOpacity(0.1)),
     elevatedButtonTheme: _sharedButtonTheme(),
     inputDecorationTheme: _sharedInputTheme(surfaceGrey, Colors.white10, electricGreen),
   );
 }


 // Light Theme Definition
 static ThemeData get lightTheme {
   return ThemeData(
     useMaterial3: true,
     brightness: Brightness.light,
     scaffoldBackgroundColor: offWhite,
     colorScheme: const ColorScheme.light(
       primary: electricGreen,
       onPrimary: Colors.white,
       secondary: obsidianBlack,
       surface: Colors.white,
       onSurface: obsidianBlack,
     ),
     textTheme: GoogleFonts.plusJakartaSansTextTheme(
       const TextTheme(
         displayLarge: TextStyle(color: obsidianBlack, fontWeight: FontWeight.bold),
         headlineMedium: TextStyle(color: obsidianBlack, fontWeight: FontWeight.w700),
         bodyLarge: TextStyle(color: obsidianBlack),
         bodyMedium: TextStyle(color: Colors.black54),
       ),
     ),
     appBarTheme: _sharedAppBar(offWhite, obsidianBlack),
     cardTheme: _sharedCardTheme(Colors.white, Colors.black.withOpacity(0.05)),
     elevatedButtonTheme: _sharedButtonTheme(),
     inputDecorationTheme: _sharedInputTheme(Colors.white, Colors.black.withOpacity(0.05), electricGreen),
   );
 }


 // Helper methods to keep code clean and modular
 static AppBarTheme _sharedAppBar(Color bg, Color text) => AppBarTheme(
       backgroundColor: bg,
       elevation: 0,
       centerTitle: true,
       iconTheme: IconThemeData(color: text),
       titleTextStyle: GoogleFonts.plusJakartaSans(
         fontSize: 20,
         fontWeight: FontWeight.bold,
         color: text,
       ),
     );


 static CardThemeData _sharedCardTheme(Color bg, Color borderColor) => CardThemeData(
       color: bg,
       elevation: 0,
       margin: const EdgeInsets.symmetric(vertical: 8),
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(24),
         side: BorderSide(color: borderColor, width: 1),
       ),
     );


 static ElevatedButtonThemeData _sharedButtonTheme() => ElevatedButtonThemeData(
       style: ElevatedButton.styleFrom(
         backgroundColor: electricGreen,
         foregroundColor: Colors.black,
         elevation: 0,
         textStyle: GoogleFonts.plusJakartaSans(
           fontWeight: FontWeight.bold,
           fontSize: 16,
         ),
         padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(16),
         ),
       ),
     );


 static InputDecorationTheme _sharedInputTheme(Color fillColor, Color borderColor, Color focusColor) =>
   InputDecorationTheme(
     filled: true,
     fillColor: fillColor,
     hintStyle: GoogleFonts.plusJakartaSans(color: subtleGrey, fontSize: 14),
     contentPadding: const EdgeInsets.all(20),
     border: OutlineInputBorder(
       borderRadius: BorderRadius.circular(16),
       borderSide: BorderSide(color: borderColor),
     ),
     enabledBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(16),
       borderSide: BorderSide(color: borderColor),
     ),
     focusedBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(16),
       borderSide: BorderSide(color: focusColor, width: 1.5),
     ),
     errorBorder: OutlineInputBorder(
       borderRadius: BorderRadius.circular(16),
       borderSide: const BorderSide(color: Colors.redAccent),
     ),
   );
}
