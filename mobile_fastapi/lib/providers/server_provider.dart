import 'package:flutter/material.dart';
import '../services/discovery_service.dart';

enum ServerStatus { disconnected, searching, found, connected, error }

class ServerProvider extends ChangeNotifier {
  final DiscoveryService _discoveryService = DiscoveryService();
  
  ServerStatus _status = ServerStatus.disconnected;
  String? _serverIp;
  int? _serverPort;
  String? _pcName;
  String _apiKey = '';

  // Getters
  ServerStatus get status => _status;
  String? get serverIp => _serverIp;
  int? get serverPort => _serverPort;
  String? get pcName => _pcName;
  String get apiKey => _apiKey;
  bool get isConnected => _status == ServerStatus.connected;

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
    notifyListeners();
  }

  void disconnect() {
    _status = ServerStatus.disconnected;
    notifyListeners();
  }
}
