import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllere pentru a prelua textul din input-uri
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  
  // Valoare default pentru Gen
  String selectedGender = 'male';

  // Funcția de înregistrare
  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // 2. LOGICĂ PENTRU DETECTAREA PLATFORMEI (WEB vs ANDROID)
    String baseUrl;
    
    if (kIsWeb) {
      // Dacă suntem pe Web (Chrome), folosim localhost standard
      baseUrl = 'http://127.0.0.1:8000'; 
    } else {
      // Dacă suntem pe mobil (Emulator Android), folosim 10.0.2.2
      baseUrl = 'http://10.0.2.2:8000'; 
    }

    final url = Uri.parse('$baseUrl/register'); 
    
    // Debugging: Să vedem în consolă ce URL a ales
    print('Încerc conectarea la: $url'); 

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text,
          'email': emailController.text,
          'password': passwordController.text,
          'gender': selectedGender,
          'weight': int.tryParse(weightController.text) ?? 70,
          'height': int.tryParse(heightController.text) ?? 175,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cont creat cu succes! Te poți loga.')),
        );
        Navigator.pop(context); 
      } else {
        // Eroare de la server
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['detail'] ?? 'Eroare la înregistrare')),
        );
      }
    } catch (e) {
      // Aici prinzi eroarea dacă serverul e oprit sau URL-ul e greșit
      print("Eroare prinsă: $e"); 
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
              // Nume
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nume'),
                validator: (value) => value!.isEmpty ? 'Introdu numele' : null,
              ),
              const SizedBox(height: 10),

              // Email
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty ? 'Introdu email-ul' : null,
              ),
              const SizedBox(height: 10),

              // Parolă
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Parolă'),
                obscureText: true,
                validator: (value) => value!.length < 4 ? 'Parola prea scurtă' : null,
              ),
              const SizedBox(height: 10),

              // Gen (Dropdown)
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

              // Greutate
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Greutate (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Introdu greutatea' : null,
              ),
              const SizedBox(height: 10),

              // Înălțime
              TextFormField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Înălțime (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Introdu înălțimea' : null,
              ),
              const SizedBox(height: 20),

              // Buton Register
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