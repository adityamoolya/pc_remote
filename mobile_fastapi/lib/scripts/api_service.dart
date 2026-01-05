import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Singleton pattern (optional, but good for global access)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final Dio _dio = Dio();

  // State to track if we are configured
  bool isConfigured = false;
  String? currentIp;

  /// Configures the connection details.
  /// Call this when the user taps a discovered device and enters the API Key.
  ///
  /// [ip] & [port]: From Bonsoir (Discovery).
  /// [apiKey]: From the Text Field user input.
  void setConnection(String ip, int port, String apiKey) {
    currentIp = ip;

    // 1. Set the Base URL (http://192.168.x.x:8000)
    _dio.options.baseUrl = 'http://$ip:$port';

    // 2. Set the Headers globally for this instance
    // All future requests will automatically include this Key.
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'X-API-Key': apiKey, // Must match your FastAPI header implementation
    };

    // 3. Set timeouts to avoid hanging if the PC goes offline
    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    isConfigured = true;
    debugPrint("🔌 API Service configured for $ip:$port with Key: $apiKey");
  }

  /// Optional: Verify the connection immediately after setting it up.
  /// Useful to tell the user "Wrong API Key" before they try to control anything.
  Future<bool> verifyConnection() async {
    if (!isConfigured) return false;

    try {
      // Assuming you have a root endpoint or a health check endpoint
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("❌ Connection verification failed: $e");
      return false;
    }
  }

  // ----------------------------------------------------------------------
  // Below are examples of how to use the configured connection
  // ----------------------------------------------------------------------

  /// Example: Send Mouse Movement
  Future<void> updateMouse(double x, double y) async {
    if (!isConfigured) return;

    try {
      await _dio.post('/mouse/move', data: {
        'x': x,
        'y': y,
      });
    } catch (e) {
      debugPrint("Error moving mouse: $e");
    }
  }

  /// Example: Send Keyboard Input
  Future<void> sendKeystroke(String key) async {
    if (!isConfigured) return;

    try {
      await _dio.post('/keyboard/press', data: {
        'key': key,
      });
    } catch (e) {
      debugPrint("Error sending key: $e");
    }
  }

  // Add this inside ApiService class
  Future<void> post(String path, [Map<String, dynamic>? data]) async {
    if (!isConfigured) return;
    try {
      await _dio.post(path, data: data);
    } catch (e) {
      debugPrint("Error sending to $path: $e");
    }
  }
}


