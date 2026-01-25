import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/discovery_service.dart';

enum ServerStatus { disconnected, searching, found, connected, error }

class ServerProvider extends ChangeNotifier {
  final DiscoveryService _discoveryService = DiscoveryService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _keyApiKey = 'pc_remote_api_key';
  static const String _keyServerIp = 'pc_remote_server_ip';
  static const String _keyServerPort = 'pc_remote_server_port';
  
  ServerStatus _status = ServerStatus.disconnected;
  String? _serverIp;
  int? _serverPort;
  String? _pcName;
  String _apiKey = '';
  bool _autoLoginAttempted = false;

  // Getters
  ServerStatus get status => _status;
  String? get serverIp => _serverIp;
  int? get serverPort => _serverPort;
  String? get pcName => _pcName;
  String get apiKey => _apiKey;
  bool get isConnected => _status == ServerStatus.connected;
  bool get hasStoredCredentials => _apiKey.isNotEmpty && _serverIp != null;

  /// Load saved credentials on app start
  Future<void> loadStoredCredentials() async {
    try {
      final storedKey = await _storage.read(key: _keyApiKey);
      final storedIp = await _storage.read(key: _keyServerIp);
      final storedPort = await _storage.read(key: _keyServerPort);
      
      if (storedKey != null && storedIp != null) {
        _apiKey = storedKey;
        _serverIp = storedIp;
        _serverPort = int.tryParse(storedPort ?? '8080') ?? 8080;
        _status = ServerStatus.found;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored credentials: $e');
    }
  }

  /// Save credentials for auto-login
  Future<void> _saveCredentials() async {
    if (_apiKey.isNotEmpty && _serverIp != null) {
      await _storage.write(key: _keyApiKey, value: _apiKey);
      await _storage.write(key: _keyServerIp, value: _serverIp!);
      await _storage.write(key: _keyServerPort, value: _serverPort.toString());
    }
  }

  /// Clear stored credentials
  Future<void> clearStoredCredentials() async {
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyServerIp);
    await _storage.delete(key: _keyServerPort);
    _apiKey = '';
  }

  // Setters
  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  void setManualIp(String ip, int port) {
    _serverIp = ip;
    _serverPort = port;
    _status = ServerStatus.found;
    notifyListeners();
  }

  // Actions
  Future<void> discover() async {
    _status = ServerStatus.searching;
    notifyListeners();

    try {
      final result = await _discoveryService.discoverServer();
      
      if (result != null) {
        _serverIp = result['ip'];
        _serverPort = result['port'];
        _pcName = result['pcName'];
        _status = ServerStatus.found;
      } else {
        _status = ServerStatus.error;
      }
    } catch (e) {
      _status = ServerStatus.error;
      debugPrint('Discovery Error: $e');
    }
    notifyListeners();
  }

  void markConnected() {
    _status = ServerStatus.connected;
    _saveCredentials(); // Save on successful connection
    notifyListeners();
  }

  void disconnect() {
    _status = ServerStatus.disconnected;
    notifyListeners();
  }
  
  void markAutoLoginAttempted() {
    _autoLoginAttempted = true;
  }
  
  bool get autoLoginAttempted => _autoLoginAttempted;
}
