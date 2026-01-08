import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiClient {
  // 🔹 LOGICĂ IP ACTUALIZATĂ
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000'; // Chrome
    } else {
      // PENTRU TELEFON FIZIC (IP-ul tău din poză):
      return 'http://192.168.0.195:8000'; 
      
      // NOTĂ: Dacă te muti vreodată pe Emulatorul Android din PC, 
      // comentează linia de sus și folosește-o pe asta:
      // return 'http://10.0.2.2:8000';
    }
  }

  // Inițializare Dio
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

  // --- RESTUL FUNCȚIILOR (NU LE-AM MODIFICAT, SUNT BUNE) ---

  Future<List<dynamic>> getUserDrinks(int userId) async {
    try {
      final response = await _dio.get('/drinks/$userId');
      return response.data; 
    } catch (e) {
      print("Eroare la preluarea istoricului: $e");
      return []; 
    }
  }

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

  Future<Response> addDrink(Map<String, dynamic> drinkData) async {
    try {
      return await _dio.post('/add_drink', data: drinkData);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getSobriety(int userId) async {
    try {
      return await _dio.get('/sobriety/$userId');
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> identifyDrink(XFile imageFile) async {
    String fileName = imageFile.name;
    FormData formData;

    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: fileName),
      });
    } else {
      formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });
    }
    return await _dio.post('/identify_drink', data: formData);
  }

  Future<bool> updateUserProfile(int userId, String name, double weight, double height) async {
    try {
      await _dio.put('/users/$userId', data: {
        "name": name,
        "weight": weight,
        "height": height,
      });
      return true;
    } catch (e) {
      print("Eroare update profil: $e");
      return false;
    }
  }
}