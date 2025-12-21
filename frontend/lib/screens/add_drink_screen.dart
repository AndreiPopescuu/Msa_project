import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- 1. IMPORT OBLIGATORIU
import '../core/api/api_client.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final api = ApiClient();

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _submitDrink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 2. CITIM ID-ul DIN MEMORIA TELEFONULUI
      final prefs = await SharedPreferences.getInstance();
      final int? storedUserId = prefs.getInt('user_id'); // <--- Aici luăm ID-ul salvat (ex: 4)

      // Verificăm dacă l-am găsit
      print("ID Utilizator găsit în memorie: $storedUserId"); // <--- DEBUG: Vezi în consolă ce ID a găsit

      if (storedUserId == null) {
        // Dacă e null, înseamnă că nu s-a salvat corect la login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eroare: Nu ești logat (ID lipsă).')),
        );
        setState(() => _loading = false);
        return;
      }

      final res = await api.addDrink({
        'user_id': storedUserId, // <--- 3. AICI FOLOSIM VARIABILA, NU MAI SCRIEM "1"
        'name': _nameCtrl.text,
        'volume_ml': double.parse(_volumeCtrl.text),
        'alcohol_percent': double.parse(_strengthCtrl.text),
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Băutură adăugată cu succes!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eroare la adăugare.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eroare conexiune: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... restul codului UI rămâne la fel ...
    return Scaffold(
      appBar: AppBar(title: const Text('Add Drink')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nume băutură'),
                validator: (v) => v!.isEmpty ? 'Introdu numele' : null,
              ),
              TextFormField(
                controller: _volumeCtrl,
                decoration: const InputDecoration(labelText: 'Volum (ml)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Introdu volumul' : null,
              ),
              TextFormField(
                controller: _strengthCtrl,
                decoration: const InputDecoration(labelText: 'Alcool (%)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Introdu procentul' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitDrink,
                      child: const Text('Adaugă'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}