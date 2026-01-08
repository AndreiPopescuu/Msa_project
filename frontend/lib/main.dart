import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

// --- 1. COMUTATORUL GLOBAL ---
// Îl definim aici ca să îl putem accesa din orice ecran
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  // --- 2. ÎNCĂRCĂM PREFERINȚA SALVATĂ ---
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Vedem dacă utilizatorul a vrut Dark Mode ultima dată
  final bool isDark = prefs.getBool('isDark') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const DrinkTrackerApp());
}

class DrinkTrackerApp extends StatelessWidget {
  const DrinkTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 3. ASCULTĂM SCHIMBĂRILE ---
    // ValueListenableBuilder reconstruiește aplicația când schimbăm tema
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Drink Tracker',
          debugShowCheckedModeBanner: false,
          
          // Setăm modul curent (Light sau Dark)
          themeMode: currentMode,
          
          // --- CUM ARATĂ MODUL LIGHT (ZI) ---
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
          ),

          // --- CUM ARATĂ MODUL DARK (NOAPTE - Stilul Cyberpunk) ---
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              secondary: Colors.blueAccent,
              surface: Color(0xFF1E1E1E),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}