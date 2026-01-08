import 'dart:io'; 
import 'package:flutter/foundation.dart' show kIsWeb; // <--- Import pentru a detecta Web-ul
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class AddDrinkScreen extends StatefulWidget {
  const AddDrinkScreen({super.key});

  @override
  State<AddDrinkScreen> createState() => _AddDrinkScreenState();
}

class _AddDrinkScreenState extends State<AddDrinkScreen> {
  final api = ApiClient();
  final ImagePicker _picker = ImagePicker(); 

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _strengthCtrl = TextEditingController();

  bool _loading = false;
  XFile? _pickedFile; // <--- Păstrăm fișierul original (XFile) pentru compatibilitate Web

  // --- LOGICA DE SCANARE ---
  Future<void> _scanDrink() async {
    try {
      // 1. Deschide camera (sau galeria)
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera, 
        imageQuality: 50, 
      );
      
      if (photo == null) return; 

      setState(() {
        _pickedFile = photo; // Salvăm referința pentru afișare
        _loading = true; 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI-ul analizează eticheta...')),
      );

      // 2. Trimite la Server (folosind XFile direct)
      final response = await api.identifyDrink(photo);

      // 3. Completează câmpurile cu ce a găsit AI-ul
      if (response.statusCode == 200) {
        final data = response.data;
        
        setState(() {
          _nameCtrl.text = data['name'] ?? '';
          if (data['abv'] != null) {
            _strengthCtrl.text = data['abv'].toString();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identificare reușită! Verifică datele.')),
        );
      } 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nu s-a putut identifica băutura.')),
      );
      print("Eroare AI: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitDrink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final int? storedUserId = prefs.getInt('user_id');

      if (storedUserId == null) return;

      // FIX: Înlocuim virgula cu punctul pentru siguranță (ex: "5,5" -> "5.5")
      double volume = double.parse(_volumeCtrl.text.replaceAll(',', '.'));
      double strength = double.parse(_strengthCtrl.text.replaceAll(',', '.'));

      await api.addDrink({
        'user_id': storedUserId,
        'name': _nameCtrl.text,
        'volume_ml': volume,
        'alcohol_percent': strength,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Băutură salvată cu succes!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Eroare: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- FUNCȚIE PENTRU AFIȘAREA IMAGINII (WEB vs MOBILE) ---
  Widget _buildImagePreview() {
    if (_pickedFile == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt, size: 60, color: Colors.blue),
          SizedBox(height: 10),
          Text("Apasă pentru a Scana Eticheta", style: TextStyle(fontSize: 16)),
        ],
      );
    }

    // Pe Web folosim NetworkImage cu path-ul blob-ului, pe Mobile folosim File
    if (kIsWeb) {
      return Image.network(_pickedFile!.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaugă Băutură')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- ZONA DE POZĂ ---
              GestureDetector(
                onTap: _scanDrink,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImagePreview(), // <--- Folosim funcția inteligentă
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- FORMULARUL ---
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nume băutură', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.local_drink),
                ),
                validator: (v) => v!.isEmpty ? 'Introdu numele' : null,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _volumeCtrl,
                      decoration: const InputDecoration(labelText: 'Volum (ml)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Introdu volumul' : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      controller: _strengthCtrl,
                      decoration: const InputDecoration(labelText: 'Alcool (%)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v!.isEmpty ? 'Introdu %' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitDrink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Salvează în Istoric', style: TextStyle(fontSize: 18)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}