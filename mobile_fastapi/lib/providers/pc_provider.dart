import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'server_provider.dart';

class PCProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ServerProvider _serverProvider;

  // State
  int _volume = 0;
  List<String> _drives = [];
  bool _isLoading = false;
  String? _lastError;

  PCProvider(this._serverProvider);

  // Getters
  int get volume => _volume;
  List<String> get drives => _drives;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Initialize API service when connection details change
  void updateConnection() {
    if (_serverProvider.serverIp != null && 
        _serverProvider.serverPort != null && 
        _serverProvider.apiKey.isNotEmpty) {
      
      _apiService.configure(
        ip: _serverProvider.serverIp!,
        port: _serverProvider.serverPort!,
        apiKey: _serverProvider.apiKey,
      );
    }
  }

  Future<bool> verifyConnection() async {
    try {
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      updateConnection();
      await _apiService.healthCheck();
      
      // Also fetch initial state if authenticated
      try {
        final volData = await _apiService.getVolume();
        _volume = volData['level'];
      } catch (e) {
        // Soft fail if auth works but volume fails
        debugPrint('Volume fetch failed during verify: $e');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Actions ---

  Future<void> refreshVolume() async {
    try {
      final result = await _apiService.getVolume();
      _volume = result['level'];
      notifyListeners();
    } catch (e) {
      debugPrint('Get Volume Error: $e');
    }
  }

  Future<void> setVolume(int level) async {
    final oldVol = _volume;
    _volume = level; // Optimistic update
    notifyListeners();

    try {
      await _apiService.setVolume(level);
    } catch (e) {
      _volume = oldVol; // Revert on failure
      notifyListeners();
    }
  }

  Future<void> mediaControl(String action) async {
    try {
      if (action == 'playpause') await _apiService.playPause();
      // Add other controls as implemented in API service
    } catch (e) {
      debugPrint('Media Control Error: $e');
    }
  }

  Future<void> fetchDrives() async {
    try {
      _isLoading = true;
      notifyListeners();
      final result = await _apiService.getDrives();
      _drives = List<String>.from(result['drives']);
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    try {
      _isLoading = true;
      notifyListeners();
      final result = await _apiService.listFiles(path);
      return List<Map<String, dynamic>>.from(result['items']);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // File operations
  Future<void> downloadFile(String path, String savePath) async {
    try {
      notifyListeners(); // Optional: set loading state if needed
      await _apiService.downloadFile(path, savePath);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  // System actions
  Future<void> lockPC() => _apiService.lock();
  Future<void> sleepPC() => _apiService.sleep();
  Future<void> shutdownPC() => _apiService.shutdown();
  Future<void> openTaskManager() => _apiService.taskManager();
}
