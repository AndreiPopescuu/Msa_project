import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllere
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  
  String selectedGender = 'male';

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // 🔹 MODIFICAREA MAGICĂ:
    // Nu mai folosim if/else cu 10.0.2.2 sau localhost.
    // Folosim direct link-ul de Cloud (Render) care merge oriunde.
    const String baseUrl = 'https://drink-tracker-2vyc.onrender.com';

    final url = Uri.parse('$baseUrl/register'); 
    
    print('🚀 Încerc conectarea la: $url'); 

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'username': nameController.text, // Backend-ul s-ar putea să ceară 'username' în loc de 'name'
          'email': emailController.text,
          'password': passwordController.text,
          'gender': selectedGender,
          'weight': int.tryParse(weightController.text) ?? 70,
          'height': int.tryParse(heightController.text) ?? 175,
        }),
      );

      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cont creat cu succes! Te poți loga.')),
        );
        Navigator.pop(context); 
      } else {
        if (!mounted) return;
        // Încercăm să decodăm eroarea, dar dacă nu e JSON valid, afișăm textul brut
        try {
            final errorData = jsonDecode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorData['detail'] ?? 'Eroare la server')),
            );
        } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Eroare: ${response.body}')),
            );
        }
      }
    } catch (e) {
      print("❌ Eroare prinsă: $e"); 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare de conexiune: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Înregistrare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nume Utilizator'),
                validator: (value) => value!.isEmpty ? 'Introdu numele' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Introdu email-ul' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Parolă'),
                obscureText: true,
                validator: (value) => value!.length < 4 ? 'Parola prea scurtă' : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: 'Gen'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Masculin')),
                  DropdownMenuItem(value: 'female', child: Text('Feminin')),
                ],
                onChanged: (val) {
                  setState(() {
                    selectedGender = val!;
                  });
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Greutate (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Introdu greutatea' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Înălțime (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Introdu înălțimea' : null,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: registerUser,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Creează Cont'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}