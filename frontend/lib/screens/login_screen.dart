import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  final api = ApiClient();
  
  bool _loading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completează toate câmpurile')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await api.login(_emailCtrl.text, _passCtrl.text);

      if (response.statusCode == 200) {
        final data = response.data;

        final prefs = await SharedPreferences.getInstance();
        if (data['user_id'] != null) {
          await prefs.setInt('user_id', data['user_id']);
        }
        if (data['username'] != null) {
          await prefs.setString('user_name', data['username']);
        }

        if (mounted) {
           Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on DioException catch (e) {
      String message = 'A apărut o eroare';

      if (e.response != null) {
        message = e.response?.data['detail'] ?? 'Date incorecte';
      } else {
        message = 'Nu se poate conecta la server. Verifică conexiunea.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Eroare: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Autentificare')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_bar, size: 80, color: Colors.blue),
            const SizedBox(height: 40),
            TextField(
              controller: _emailCtrl, 
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email)
              )
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passCtrl, 
              obscureText: true, 
              decoration: const InputDecoration(
                labelText: 'Parolă',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock)
              )
            ),
            const SizedBox(height: 30),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              }, 
              child: const Text("Nu ai cont? Înregistrează-te")
            )
          ],
        ),
      ),
    );
  }
}