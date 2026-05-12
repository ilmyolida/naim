import 'package:flutter/material.dart';

/// Ilova mavzularini markazlashtirilgan boshqarish klassi.
/// Bu yerda faqat ranglar va shriftlar saqlanadi.
class AppTheme {
  // Ko'zni charchatmaydigan Soft Cream ranglar palitrasi
  static const Color _softCreamScaffoldBg = Color(0xFFFDF6E3); // Mayin krem fon
  static const Color _softCreamAppBarBg = Color(0xFFEEE8D5); // Biroz to'qroq krem
  static const Color _softCreamText = Color(0xFF586E75); // To'q kulrang-yashil matn
  static const Color _primaryAccent = Color(0xFF00BFA5); // Taqdim etgan suratlardagi asosiy aksent yashil rangi

  // --- Light Mode (Oq Fon) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: _primaryAccent,
    brightness: Brightness.light,
    
    // Ilova fonining rangi
    scaffoldBackgroundColor: Colors.white,
    
    // Yuqori panel dizayni (image_0.png dagi kabi oq)
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87, // Sarlavha va ikon ranglari
      elevation: 0, // Soya bo'lmasligi uchun
    ),
    
    // BottomNavigationBar dizayni (image_0.png dagi kabi)
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: _primaryAccent,
      unselectedItemColor: Colors.black54,
    ),
    
    // So'z kartochkalari dizayni
    cardTheme: CardTheme(
      color: const Color(0xFFFBFBFB), // Judayam mayin oq
      elevation: 1, // Kichik soya
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),

    // Matnlar stilini sozlash
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black87, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 16),
    ),
  );

  // --- Soft Cream Mode (Siz so'ragandek sariqish rejim) ---
  static final ThemeData softCreamTheme = ThemeData(
    useMaterial3: true,
    primaryColor: _primaryAccent,
    brightness: Brightness.light,
    
    // Ilova fonining rangi (Sariqish krem)
    scaffoldBackgroundColor: _softCreamScaffoldBg,
    
    // Yuqori panel krem rejimida
    appBarTheme: const AppBarTheme(
      backgroundColor: _softCreamAppBarBg,
      foregroundColor: _softCreamText,
      elevation: 0,
    ),
    
    // BottomNavigationBar krem rejimida
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _softCreamAppBarBg,
      selectedItemColor: _primaryAccent,
      unselectedItemColor: Colors.black54,
    ),
    
    // So'z kartochkalari krem rejimida biroz yorqinroq
    cardTheme: CardTheme(
      color: Colors.white, // Kartochkalar oq bo'lsa fonda ajralib turadi
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),

    // Matnlar stilini krem rejimiga moslash
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: _softCreamText, fontSize: 22, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: _softCreamText, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 16),
    ),
  );
}