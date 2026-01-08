import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final api = ApiClient();
  
  // Controllere pentru câmpuri
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  bool _isLoading = false;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // Încărcăm datele actuale din telefon (sau ai putea să le ceri de la server)
  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('user_id');
      _nameController.text = prefs.getString('user_name') ?? '';
      
      // Aici punem valori default dacă nu avem salvat nimic încă
      // Ideal ar fi să le luăm din backend la login
      double w = prefs.getDouble('user_weight') ?? 75.0; 
      double h = prefs.getDouble('user_height') ?? 175.0;
      
      _weightController.text = w.toString();
      _heightController.text = h.toString();
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (userId == null) return;

    setState(() => _isLoading = true);

    String newName = _nameController.text;
    double newWeight = double.tryParse(_weightController.text) ?? 70.0;
    double newHeight = double.tryParse(_heightController.text) ?? 170.0;

    // 1. Trimitem la Server
    bool success = await api.updateUserProfile(userId!, newName, newWeight, newHeight);

    if (success) {
      // 2. Salvăm și local în telefon ca să ținem minte
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', newName);
      await prefs.setDouble('user_weight', newWeight);
      await prefs.setDouble('user_height', newHeight);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil actualizat cu succes! ✅')),
        );
        Navigator.pop(context, true); // Ne întoarcem cu "true" ca să dăm refresh la Home
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eroare la salvare. Verifică serverul.')),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editare Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 30),
              
              // --- NUME ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nume Utilizator",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Introdu un nume" : null,
              ),
              const SizedBox(height: 20),

              // --- GREUTATE & ÎNĂLȚIME (Pe același rând) ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Greutate (kg)",
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? "Necesar" : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Înălțime (cm)",
                        prefixIcon: Icon(Icons.height),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val!.isEmpty ? "Necesar" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // --- BUTON SAVE ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Salvează Modificările", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}