import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import necesar pentru kIsWeb
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  // 🔹 LOGICĂ AUTOMATĂ PENTRU IP
  // Această funcție decide la ce adresă să se conecteze
  static String get baseUrl {
    if (kIsWeb) {
      // Dacă rulezi în Browser (Chrome)
      return 'http://127.0.0.1:8000';
    } else {
      // Dacă rulezi pe Emulator Android
      // (Dacă folosești telefon fizic, schimbă aici cu IP-ul PC-ului tău, ex: 192.168.1.5:8000)
      return 'http://10.0.2.2:8000';
    }
  }


  /*Future<Response> identifyDrink(XFile imageFile) async {
    // 1. Pregătim fișierul
    String fileName = imageFile.path.split('/').last;
    
    // 2. Îl împachetăm ca FormData (așa cum vrea serverul)
    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        imageFile.path,
        filename: fileName,
      ),
    });
    return await _dio.post('/identify_drink', data: formData);
  }*/

  Future<List<dynamic>> getUserDrinks(int userId) async {
    try {
      final response = await _dio.get('/drinks/$userId');
      // Returnăm lista de date (ex: [{name: "Bere", ...}, {name: "Vin", ...}])
      return response.data; 
    } catch (e) {
      print("Eroare la preluarea istoricului: $e");
      return []; // Dacă e eroare, întoarcem o listă goală ca să nu crape aplicația
    }
  }

  // Inițializare Dio cu URL-ul dinamic
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl, 
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ✅ 1. LOGIN
  Future<Response> login(String email, String password) async {
    try {
      return await _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 2. REGISTER
  Future<Response> register(String email, String username, String password) async {
    try {
      return await _dio.post('/register', data: {
        'email': email,
        'username': username,
        'password': password,
        'weight': 70, 
        'gender': 'unknown' 
      });
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 3. ADĂUGARE BĂUTURĂ MANUAL
  Future<Response> addDrink(Map<String, dynamic> drinkData) async {
    try {
      return await _dio.post('/add_drink', data: drinkData);
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 4. SOBRIETY LEVEL
  Future<Response> getSobriety(int userId) async {
    try {
      return await _dio.get('/sobriety/$userId');
    } catch (e) {
      rethrow;
    }
  }

  // ✅ 5. AI - IDENTIFICARE BĂUTURĂ (Upload Poză)
  Future<Response> identifyDrink(XFile imageFile) async {
    String fileName = imageFile.name; // Luăm numele direct din XFile
    
    FormData formData;

    if (kIsWeb) {
      // --- LOGICA PENTRU WEB (CHROME) ---
      // Pe web nu avem "cale", deci citim fișierul ca o serie de bytes (0 și 1)
      final bytes = await imageFile.readAsBytes();
      formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes, 
          filename: fileName
        ),
      });
    } else {
      // --- LOGICA PENTRU MOBIL (ANDROID) ---
      // Pe mobil avem acces la fișiere, e mai eficient să trimitem calea
      formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          imageFile.path, 
          filename: fileName
        ),
      });
    }

    // Trimitem la server
    return await _dio.post('/identify_drink', data: formData);
  }

  Future<bool> updateUserProfile(int userId, String name, double weight, double height) async {
    try {
      await _dio.put('/users/$userId', data: {
        "name": name,
        "weight": weight,
        "height": height,
      });
      return true; // Succes
    } catch (e) {
      print("Eroare update profil: $e");
      return false; // Eșec
    }
  }
}