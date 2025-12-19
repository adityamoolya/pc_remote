import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'connection_service.dart';
import 'home_page.dart';
import 'files_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Used to show SnackBars only once
  ConnectionStatus _previousStatus = ConnectionStatus.disconnected;

  void _onItemTapped(int index) {
    // Block tapping "Files" tab if not connected
    if (index == 1 &&
        Provider.of<ConnectionService>(context, listen: false)
            .connectionStatus !=
            ConnectionStatus.connected) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please connect to the server first.'),
        backgroundColor: Colors.amber,
      ));
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showQRScannerDialog(ConnectionService connection) async {
    // --- ADD THIS FLAG ---
    bool isPopped = false;

    final String? scannedData = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        // ... (rest of your dialog setup) ...
        child: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: MobileScanner(
              onDetect: (capture) {
                // --- ADD THIS CHECK ---
                if (isPopped) return;

                final List<Barcode> barcodes = capture.barcodes;

                // Add a null check for safety
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {

                  // --- SET THE FLAG ---
                  isPopped = true;

                  // Pop with the first valid QR code
                  Navigator.of(context).pop(barcodes.first.rawValue);
                }
              },
            ),
          ),
        ),
      ),
    );

    // --- Safe QR Code Handling ---
    try {
      if (scannedData != null && scannedData.contains('|')) {
        final parts = scannedData.split('|');
        if (parts.length == 2) {
          // Start the connection. The UI will update via the Provider.
          connection.connect(parts[0], parts[1]);
        } else {
          throw Exception("Invalid QR code format.");
        }
      } else if (scannedData != null) {
        throw Exception("Not a valid server QR code.");
      }
    } catch (e) {
      // Catch any QR parsing errors and show a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // Helper to build the connect/disconnect/loading button
  Widget _buildConnectButtonChild(ConnectionService connection) {
    switch (connection.connectionStatus) {
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Colors.white,
          ),
        );
      case ConnectionStatus.connected:
        return const Text('Disconnect', style: TextStyle(color: Colors.redAccent));
      case ConnectionStatus.disconnected:
      default:
        return const Text('Connect', style: TextStyle(color: Colors.greenAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Consumer is the old way, context.watch is the new way
    // Let's stick with Consumer as you had it
    return Consumer<ConnectionService>(
      builder: (context, connection, child) {

        // --- SnackBar Logic ---
        final currentStatus = connection.connectionStatus;
        if (currentStatus != _previousStatus) {
          // Show SnackBar *after* the build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Show "Connected" message
              if (currentStatus == ConnectionStatus.connected) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  // --- CHANGE THIS LINE ---
                  content: Text('Connected to ${connection.connectedIp}'),
                  backgroundColor: Colors.green,
                ));
              }
              // Show "Failed" message
              else if (_previousStatus == ConnectionStatus.connecting &&
                  currentStatus == ConnectionStatus.disconnected) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(connection.statusMessage),
                  backgroundColor: Colors.redAccent,
                ));
              }
            }
          });
          _previousStatus = currentStatus;
        }
        // --- End SnackBar Logic ---

        final pages = <Widget>[
          const HomePage(),
          const FilesPage(), // No socket parameter needed!
          const Center(child: Text('Settings Page')),
        ];

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 35.0,
            backgroundColor: Colors.black26,
            title: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: connection.connectionStatus == ConnectionStatus.connected
                      ? Colors.green
                      : connection.connectionStatus == ConnectionStatus.connecting
                      ? Colors.amber // Yellow for loading
                      : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    connection.statusMessage, // Shows "Connecting..." etc.
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                // if (connection.connectionStatus == ConnectionStatus.connected)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 8.0),
                //     child: Text('(${connection.connectedIp})'),
                //   ),
              ],
            ),
            actions: [
              TextButton(
                // Disable button while connecting
                onPressed: connection.connectionStatus == ConnectionStatus.connecting
                    ? null
                    : () {
                  if (connection.connectionStatus == ConnectionStatus.connected) {
                    connection.disconnect('Disconnected.');
                    if (_selectedIndex == 1) _onItemTapped(0); // Go home
                  } else {
                    _showQRScannerDialog(connection);
                  }
                },
                child: _buildConnectButtonChild(connection),
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Explorer'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        );
      },
    );
  }
}