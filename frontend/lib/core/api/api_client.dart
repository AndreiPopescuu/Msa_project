import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Import necesar pentru kIsWeb

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
  Future<Response> identifyDrink(String filePath, int userId) async {
    try {
      String fileName = filePath.split('/').last;
      
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      return await _dio.post(
        '/identifyDrink',
        queryParameters: {'user_id': userId},
        data: formData,
      );
    } catch (e) {
      rethrow;
    }
  }
}