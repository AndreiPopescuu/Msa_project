import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/add_drink_screen.dart'; // <--- 1. Asigură-te că ai importul ăsta!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drink Tracker',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login', 
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/register': (context) => const RegisterScreen(),
        
        // ⚠️ 2. LINIA CRITICĂ: Trebuie să fie scrisă EXACT așa:
        '/add_drink': (context) => const AddDrinkScreen(), 
      },
    );
  }
}