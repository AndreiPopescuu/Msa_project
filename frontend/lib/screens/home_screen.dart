import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../main.dart'; // Importăm pentru themeNotifier
import 'add_drink_screen.dart';
import 'stats_screen.dart'; // Asigură-te că ai acest import
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final api = ApiClient();
  
  int? userId;
  String? userName;
  double sobrietyLevel = 1.0; 
  List<dynamic> drinksHistory = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _refreshData() {
    _loadData();
  }

  void _toggleTheme() async {
    final isDarkCurrently = themeNotifier.value == ThemeMode.dark;
    final newMode = isDarkCurrently ? ThemeMode.light : ThemeMode.dark;
    themeNotifier.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', newMode == ThemeMode.dark);
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('user_id');
    final storedName = prefs.getString('user_name');

    if (storedId != null) {
      try {
        try {
           final sobrietyResponse = await api.getSobriety(storedId);
           if (sobrietyResponse.statusCode == 200) {
             sobrietyLevel = sobrietyResponse.data['sobriety_level'];
           }
        } catch (e) {
           print("Eroare sobrietate: $e");
        }
        final historyList = await api.getUserDrinks(storedId);

        if (mounted) {
          setState(() {
            userId = storedId;
            userName = storedName ?? 'Utilizator';
            drinksHistory = historyList; 
            isLoading = false;
          });
        }
      } catch (e) {
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

  Color _getBarColor(double level) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (level > 0.75) return isDark ? Colors.greenAccent : Colors.green;
    if (level > 0.40) return isDark ? Colors.orangeAccent : Colors.orange;
    return isDark ? Colors.redAccent : Colors.red;
  }

  Map<String, List<dynamic>> _groupDrinksByDate(List<dynamic> allDrinks) {
    Map<String, List<dynamic>> grouped = {};
    for (var drink in allDrinks) {
      String rawDate = drink['created_at'] ?? '';
      String dateKey = rawDate.split('T')[0]; 
      if (dateKey.isEmpty) dateKey = "Necunoscut";
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(drink);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedHistory = _groupDrinksByDate(drinksHistory);
    final sortedDates = groupedHistory.keys.toList();
    bool isDarkMode = themeNotifier.value == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Salut, ${userName ?? "Guest"}!'),
        actions: [
          
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () async {
              // Așteptăm să se întoarcă de la profil
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              // Dacă a dat save (result == true), reîncărcăm numele pe Home
              if (result == true) {
                _refreshData();
              }
            },
          ),

          // --- 1. AICI AM FĂCUT CURĂȚENIE (Doar 3 butoane) ---
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Schimbă Tema',
            onPressed: _toggleTheme,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // --- CARD SOBRIETATE ---
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const Text("Nivel Sobrietate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: sobrietyLevel,
                              minHeight: 25,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[800] 
                                  : Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_getBarColor(sobrietyLevel)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text("${(sobrietyLevel * 100).toInt()}% Treaz",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _getBarColor(sobrietyLevel))),
                        ],
                      ),
                    ),
                  ),
                ),

                const Divider(thickness: 1), 
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Istoric pe Zile", 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color 
                      )),
                  ),
                ),

                // --- LISTA ---
                Expanded(
                  child: drinksHistory.isEmpty
                      ? const Center(child: Text("Nu ai băut nimic încă.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100), // Spațiu jos pentru butoane
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            String dateKey = sortedDates[index];
                            List<dynamic> daysDrinks = groupedHistory[dateKey]!;
                            
                            bool isDark = Theme.of(context).brightness == Brightness.dark;
                            Color headerBg = isDark ? Colors.white10 : Colors.grey[200]!;
                            Color headerText = isDark ? Colors.blue[200]! : Colors.blue[800]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  width: double.infinity,
                                  color: headerBg, 
                                  child: Text(
                                    dateKey,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: headerText,
                                      fontSize: 16
                                    ),
                                  ),
                                ),
                                ...daysDrinks.map((drink) {
                                  return Card(
                                    elevation: 0, 
                                    color: Colors.transparent,
                                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.withOpacity(0.2),
                                        child: const Icon(Icons.local_drink, color: Colors.blue, size: 20),
                                      ),
                                      title: Text(drink['name'] ?? 'Băutură', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Text("${drink['volume_ml']}ml | ${drink['alcohol_percent']}% Alcool", 
                                        style: const TextStyle(color: Colors.grey)), 
                                      trailing: Text(
                                        (drink['created_at'] ?? '').split('T')[1].substring(0, 5),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
      
      // --- 2. ZONA DE BUTOANE JOS (Stânga & Dreapta) ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, // Le centrăm ca să avem control
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20), // Margini stânga-dreapta
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Unul la stânga, unul la dreapta
          children: [
            // BUTON STATISTICI (STÂNGA)
            FloatingActionButton(
              heroTag: "btnStats", // <--- CRITIC: Tag unic
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
              foregroundColor: Colors.blue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatsScreen(drinksHistory: drinksHistory),
                  ),
                );
              },
              child: const Icon(Icons.bar_chart),
            ),

            // BUTON ADAUGĂ (DREAPTA)
            FloatingActionButton.extended(
              heroTag: "btnAdd", // <--- CRITIC: Tag unic
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDrinkScreen()),
                );
                _refreshData(); 
              },
              label: const Text("Adaugă"),
              icon: const Icon(Icons.add),
              backgroundColor: Colors.blue, 
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}