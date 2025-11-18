import 'package:flutter/material.dart';

import '../core/api/api_client.dart';
import '../widgets/sober_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiClient();
  double? sobrietyLevel;

  @override
  void initState() {
    super.initState();
    fetchSobriety();
  }

  Future<void> fetchSobriety() async {
    try {
      final res = await api.getSobriety(1);
      setState(() {
        sobrietyLevel = res.data['sobriety_level'] * 1.0;
      });
    } catch (e) {
      debugPrint('Eroare la fetch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MSA Home')),
      body: Center(
        child: sobrietyLevel == null
            ? const CircularProgressIndicator()
            : SoberBar(sobrietyLevel: sobrietyLevel!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-drink'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
