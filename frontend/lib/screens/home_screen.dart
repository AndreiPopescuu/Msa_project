import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart'; // Asigură-te că importul e corect
import 'add_drink_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiClient();
  
  // Date utilizator
  int? userId;
  String? userName;
  
  // Date sobrietate
  double sobrietyLevel = 1.0; // 1.0 = 100% Treaz
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Această funcție se apelează când ne întoarcem de la "Add Drink"
  // Ca să actualizăm bara imediat
  void _refreshData() {
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id');
    final storedName = prefs.getString('user_name');

    if (storedId != null) {
      try {
        // Cerem nivelul de la server folosind ID-ul salvat
        final response = await api.getSobriety(storedId);
        
        if (response.statusCode == 200) {
          // Backend-ul returnează ex: {"sobriety_level": 0.85}
          final double level = response.data['sobriety_level'];
          
          if (mounted) {
            setState(() {
              userId = storedId;
              userName = storedName ?? 'Utilizator';
              sobrietyLevel = level; // Actualizăm bara
              isLoading = false;
            });
          }
        }
      } catch (e) {
        print("Eroare la preluarea sobrietății: $e");
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Funcție ajutătoare pentru culoarea barei
  Color _getBarColor(double level) {
    if (level > 0.75) return Colors.green; // Treaz
    if (level > 0.40) return Colors.orange; // Amețit
    return Colors.red; // Beat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salut, ${userName ?? "Guest"}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData, // Buton manual de refresh
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userId == null) {
            return Center(
              child: ElevatedButton(
                onPressed: _logout,
                child: const Text("Eroare autentificare. Mergi la Login"),
              ),
            );
          }

          // --- UI PRINCIPAL CU BARA ---
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card pentru Sobrietate
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          "Nivel Sobrietate",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        
                        // BARA PROPRIU-ZISĂ
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: sobrietyLevel, // Valoarea de la server (0.0 la 1.0)
                            minHeight: 25,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getBarColor(sobrietyLevel),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        Text(
                          "${(sobrietyLevel * 100).toInt()}% Treaz",
                          style: TextStyle(
                            fontSize: 22, 
                            fontWeight: FontWeight.bold,
                            color: _getBarColor(sobrietyLevel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                const Center(child: Text("Istoric băuturi (urmează...)")),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Așteptăm să se întoarcă de la ecranul de Add Drink
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDrinkScreen()),
          );
          // Când se întoarce, dăm refresh la bară automat
          _refreshData();
        },
        label: const Text("Adaugă Băutură"),
        icon: const Icon(Icons.local_drink),
        backgroundColor: Colors.blue,
      ),
    );
  }
}