import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.1.100:8000', // înlocuiește cu IP-ul PC-ului tău
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  Future<Response> login(String email, String password) {
    return _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
  }

  Future<Response> getSobriety(int userId) {
    return _dio.get('/sobriety/$userId');
  }

  Future<Response> addDrink(Map<String, dynamic> drinkData) {
    return _dio.post('/add_drink', data: drinkData);
  }
}
