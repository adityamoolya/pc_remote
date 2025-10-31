import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// The 'state' of our connection
enum ConnectionStatus { disconnected, connecting, connected }

class ConnectionService extends ChangeNotifier {
  Socket? _socket;
  Stream<Uint8List>? _socketStream; // The new broadcast stream
  StreamSubscription<Uint8List>? _authSubscription;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String _connectedIp = '';
  String _statusMessage = "Disconnected";

  // Public getters
  ConnectionStatus get connectionStatus => _connectionStatus;
  Stream<Uint8List>? get socketStream => _socketStream;
  String get connectedIp => _connectedIp;
  String get statusMessage => _statusMessage; // Renamed from 'status'
  Socket? get socket => _socket;
  void connect(String url, String secretKey) {
    // 1. Set state to 'connecting'
    if (_connectionStatus == ConnectionStatus.connecting) return;
    _connectionStatus = ConnectionStatus.connecting;
    _statusMessage = 'Connecting...';
    notifyListeners();

    // No "try...catch" here
    final uri = Uri.parse(url);

    // Socket.connect returns a Future. We handle it with .then()
    // This runs the network code in the background and does NOT block the UI.
    Socket.connect(
      uri.host,
      uri.port,
      timeout: const Duration(seconds: 10),
    )
        .then((Socket newSocket) {
      // This code runs ONLY if the connection is successful
      _socket = newSocket;
      _socketStream = _socket!.asBroadcastStream();
      _socket!.write('AUTH $secretKey\n');

      // Set up the auth listener
      _authSubscription = _socketStream!.listen(
            (data) {
          final message = String.fromCharCodes(data).trim();
          if (message == 'AUTH_OK') {
            _connectionStatus = ConnectionStatus.connected;
            _connectedIp = uri.host;
            _statusMessage = 'Connected';

            // Auth is done, cancel this listener so FilesPage can listen
            _authSubscription?.cancel();
            _authSubscription = null;
            notifyListeners();

          } else if (message == 'AUTH_FAIL') {
            disconnect('Authentication Failed.');
          }
        },
        onDone: () => disconnect('Server disconnected.'),
        onError: (error) => disconnect('Connection error: $error'),
        cancelOnError: true,
      );
    })
        .catchError((e) {
      // This code runs if Socket.connect fails (timeout, refused, etc.)
      disconnect('Connection error');

    });
  }

  // --- Also, make sure your 'disconnect' function has this ---
  // @override
  void disconnect([String? reason]) {
    if (_connectionStatus == ConnectionStatus.disconnected) return;

    _authSubscription?.cancel(); // <-- Make sure this line is here
    _authSubscription = null;

    _socket?.destroy();
    _socket = null;
    _socketStream = null;
    _connectionStatus = ConnectionStatus.disconnected;
    _connectedIp = '';
    _statusMessage = reason ?? "Disconnected";
    notifyListeners();
  }

  // void disconnect([String? reason]) {
  //   if (_connectionStatus == ConnectionStatus.disconnected) return;
  //
  //   _socket?.destroy();
  //   _socket = null;
  //   _socketStream = null;
  //   _connectionStatus = ConnectionStatus.disconnected;
  //   _connectedIp = '';
  //   _statusMessage = reason ?? "Disconnected";
  //   notifyListeners();
  // }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}