import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

enum AppConnectionState { disconnected, discovering, connecting, connected }
enum ConnectionMode { none, lan, broadcast }

class DiscoveredServer {
  final String name;
  final String ip;
  final int port;

  DiscoveredServer({required this.name, required this.ip, required this.port});
}

class ConnectionProvider extends ChangeNotifier {
  final ApiService api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppConnectionState _state = AppConnectionState.disconnected;
  ConnectionMode _connectionMode = ConnectionMode.none;
  DiscoveredServer? _server;
  String? _apiKey;
  String _statusMessage = 'Looking for your PC...';
  String? _broadcastBaseUrl;

  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;
  final List<DiscoveredServer> _discoveredServers = [];

  // Public getters
  AppConnectionState get state => _state;
  ConnectionMode get connectionMode => _connectionMode;
  DiscoveredServer? get server => _server;
  String? get apiKey => _apiKey;
  String get statusMessage => _statusMessage;
  String? get broadcastBaseUrl => _broadcastBaseUrl;
  List<DiscoveredServer> get discoveredServers => List.unmodifiable(_discoveredServers);
  bool get isBroadcastMode => _connectionMode == ConnectionMode.broadcast;
  bool get isConnected => _state == AppConnectionState.connected;

  // Storage keys
  static const _keyApiKey = 'pc_remote_api_key';
  static const _keyServerIp = 'pc_remote_server_ip';
  static const _keyServerPort = 'pc_remote_server_port';

  // ─── Init ───
  Future<void> init() async {
    _apiKey = await _storage.read(key: _keyApiKey);
    startDiscovery();
  }

  // ─── mDNS Discovery ───
  Future<void> startDiscovery() async {
    _state = AppConnectionState.discovering;
    _statusMessage = 'Scanning network...';
    _discoveredServers.clear();
    notifyListeners();

    stopDiscovery();
    _discovery = BonsoirDiscovery(type: '_pcremote._tcp');
    await _discovery!.initialize();
    _discoverySub = _discovery!.eventStream?.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        _discovery?.serviceResolver.resolveService(event.service);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;
        final ip = service.host ?? '';
        final port = service.port;
        final name = service.name;

        if (ip.isNotEmpty) {
          final exists = _discoveredServers.any((s) => s.ip == ip && s.port == port);
          if (!exists) {
            _discoveredServers.add(DiscoveredServer(name: name, ip: ip, port: port));
            notifyListeners();
          }
        }
      } else if (event is BonsoirDiscoveryServiceLostEvent) {
        final service = event.service;
        _discoveredServers.removeWhere((s) => s.name == service.name);
        notifyListeners();
      }
    });
    await _discovery!.start();
  }

  void stopDiscovery() {
    _discoverySub?.cancel();
    _discoverySub = null;
    _discovery?.stop();
    _discovery = null;
  }

  // ─── Key management ───
  bool get hasSavedKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<void> saveApiKey(String key) async {
    _apiKey = key;
    await _storage.write(key: _keyApiKey, value: key);
    notifyListeners();
  }

  // ─── Connect ───
  Future<bool> connectToServer(DiscoveredServer server) async {
    if (_apiKey == null || _apiKey!.isEmpty) return false;

    _state = AppConnectionState.connecting;
    _statusMessage = 'Connecting to ${server.name}...';
    _server = server;
    notifyListeners();

    _connectionMode = ConnectionMode.lan;
    final baseUrl = 'http://${server.ip}:${server.port}';
    api.configure(baseUrl: baseUrl, apiKey: _apiKey!);

    final ok = await api.healthCheck();
    if (ok) {
      _state = AppConnectionState.connected;
      _statusMessage = 'Connected to ${server.name}';
      await _storage.write(key: _keyServerIp, value: server.ip);
      await _storage.write(key: _keyServerPort, value: server.port.toString());
      stopDiscovery();
      notifyListeners();
      return true;
    } else {
      _state = AppConnectionState.discovering;
      _statusMessage = 'Connection failed. Check API key.';
      _server = null;
      notifyListeners();
      return false;
    }
  }

  // ─── Disconnect ───
  void disconnect() {
    _state = AppConnectionState.disconnected;
    _statusMessage = 'Disconnected';
    _server = null;
    notifyListeners();
  }

  // ─── Broadcast Connect ───
  Future<bool> connectBroadcast(String cloudflareUrl, String apiKey) async {
    // Validate and clean URL
    String url = cloudflareUrl.trim();
    if (!url.startsWith('https://')) return false;
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    _connectionMode = ConnectionMode.broadcast;
    _broadcastBaseUrl = url;
    _state = AppConnectionState.connecting;
    _statusMessage = 'Connecting to broadcast server...';
    _apiKey = apiKey;
    await _storage.write(key: _keyApiKey, value: apiKey);
    notifyListeners();

    api.configure(baseUrl: url, apiKey: apiKey);

    final ok = await api.healthCheck();
    if (ok) {
      _state = AppConnectionState.connected;
      _statusMessage = 'Connected via Broadcast';
      stopDiscovery();
      notifyListeners();
      return true;
    } else {
      _state = AppConnectionState.disconnected;
      _statusMessage = 'Broadcast connection failed.';
      _connectionMode = ConnectionMode.none;
      _broadcastBaseUrl = null;
      notifyListeners();
      return false;
    }
  }

  // ─── Switch Mode ───
  void switchMode() {
    _connectionMode = ConnectionMode.none;
    _state = AppConnectionState.disconnected;
    _statusMessage = 'Disconnected';
    _server = null;
    _broadcastBaseUrl = null;
    notifyListeners();
  }

  // ─── Unpair ───
  Future<void> unpair() async {
    await _storage.delete(key: _keyApiKey);
    await _storage.delete(key: _keyServerIp);
    await _storage.delete(key: _keyServerPort);
    _apiKey = null;
    _server = null;
    _state = AppConnectionState.disconnected;
    _statusMessage = 'Unpaired';
    startDiscovery();
    notifyListeners();
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }
}
