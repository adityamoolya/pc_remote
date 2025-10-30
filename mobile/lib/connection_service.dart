import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// The 'state' of our connection
enum ConnectionStatus { disconnected, connecting, connected }

class ConnectionService extends ChangeNotifier {
  Socket? _socket;
  Stream<Uint8List>? _socketStream; // The new broadcast stream

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String _connectedIp = '';
  String _statusMessage = "Disconnected";

  // Public getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  Stream<Uint8List>? get socketStream => _socketStream;
  String get connectedIp => _connectedIp;
  String get statusMessage => _statusMessage; // Renamed from 'status'
  Socket? get socket => _socket;
  Future<void> connect(String url, String secretKey) async {
    // 1. Set state to 'connecting'
    if (_connectionStatus == ConnectionStatus.connecting) return;
    _connectionStatus = ConnectionStatus.connecting;
    _statusMessage = 'Connecting...';
    notifyListeners();

    try {
      final uri = Uri.parse(url);
      _socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 10), // 10-second timeout
      );

      // 2. Create the broadcast stream that multiple widgets can listen to
      _socketStream = _socket!.asBroadcastStream();

      // 3. Send auth
      _socket!.write('AUTH $secretKey\n');

      // 4. Set up the *service's* listener (for auth)
      _socketStream!.listen(
            (data) {
          final message = String.fromCharCodes(data).trim();
          if (message == 'AUTH_OK') {
            _connectionStatus = ConnectionStatus.connected;
            _connectedIp = uri.host;
            _statusMessage = 'Connected to $connectedIp';
            notifyListeners();
          } else if (message == 'AUTH_FAIL') {
            disconnect('Authentication Failed.');
          }
          // It will also receive file data, but will just ignore it
        },
        onDone: () => disconnect('Server disconnected.'),
        onError: (error) => disconnect('Connection error: $error'),
        cancelOnError: true,
      );
    } catch (e) {
      disconnect('Server could not be connected.');
    }
  }

  void disconnect([String? reason]) {
    if (_connectionStatus == ConnectionStatus.disconnected) return;

    _socket?.destroy();
    _socket = null;
    _socketStream = null;
    _connectionStatus = ConnectionStatus.disconnected;
    _connectedIp = '';
    _statusMessage = reason ?? "Disconnected";
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}