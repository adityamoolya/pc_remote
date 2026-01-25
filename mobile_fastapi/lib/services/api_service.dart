import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  String? _baseUrl;
  String? _apiKey;

  ApiService() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  void configure({required String ip, required int port, required String apiKey}) {
    _baseUrl = 'http://$ip:$port';
    _apiKey = apiKey;
    _dio.options.baseUrl = _baseUrl!;
    _dio.options.headers = {'PLEASE_LET_ME_IN': _apiKey};
  }

  bool get isConfigured => _baseUrl != null && _apiKey != null;

  // ============ HEALTH ============
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _dio.get('/');
    return response.data;
  }

  // ============ SYSTEM ROUTES ============
  Future<Map<String, dynamic>> lock() async {
    final response = await _dio.post('/system/lock');
    return response.data;
  }

  Future<Map<String, dynamic>> sleep() async {
    final response = await _dio.post('/system/sleep');
    return response.data;
  }

  Future<Map<String, dynamic>> shutdown() async {
    final response = await _dio.post('/system/shutdown');
    return response.data;
  }

  Future<Map<String, dynamic>> taskManager() async {
    final response = await _dio.post('/system/taskmanager');
    return response.data;
  }

  // ============ FILES ROUTES ============
  Future<Map<String, dynamic>> getDrives() async {
    final response = await _dio.get('/files/drives');
    return response.data;
  }

  Future<Map<String, dynamic>> listFiles(String path) async {
    final response = await _dio.get('/files/list', queryParameters: {'path': path});
    return response.data;
  }

  Future<void> downloadFile(String path, String savePath) async {
    // Assuming backend endpoint /files/download?path=...
    await _dio.download('/files/download', savePath, queryParameters: {'path': path});
  }

  // ============ MEDIA ROUTES ============
  Future<Map<String, dynamic>> getVolume() async {
    final response = await _dio.get('/media/volume');
    return response.data;
  }

  Future<Map<String, dynamic>> setVolume(int level) async {
    final response = await _dio.post('/media/volume/$level');
    return response.data;
  }

  Future<Map<String, dynamic>> playPause() async {
    final response = await _dio.post('/media/playpause');
    return response.data;
  }
}
