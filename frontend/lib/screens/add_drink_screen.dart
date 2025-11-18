import 'package:flutter/material.dart';

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
      final res = await api.addDrink({
        'user_id': 1, // temporary hardcoded user, update later
        'name': _nameCtrl.text,
        'volume_ml': double.parse(_volumeCtrl.text),
        'alcohol_percent': double.parse(_strengthCtrl.text),
      });

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drink added successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error adding drink.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(labelText: 'Drink name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter a drink name' : null,
              ),
              TextFormField(
                controller: _volumeCtrl,
                decoration:
                    const InputDecoration(labelText: 'Volume (ml)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter the volume' : null,
              ),
              TextFormField(
                controller: _strengthCtrl,
                decoration: const InputDecoration(
                    labelText: 'Alcohol percentage (%)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter the percentage' : null,
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitDrink,
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
