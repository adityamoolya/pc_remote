import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/server_provider.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/media_tab.dart';
import 'tabs/files_tab.dart';
import 'tabs/profile_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  ServerStatus _previousStatus = ServerStatus.disconnected;

  final List<Widget> _pages = [
    const DashboardTab(),
    const FilesTab(),
    const MediaTab(),
    const ProfileTab(),
  ];

  void _onItemTapped(int index) {
    if (index == 1 &&
        context.read<ServerProvider>().status != ServerStatus.connected) {
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

  Future<void> _showQRScannerDialog() async {
    final server = context.read<ServerProvider>();
    bool isPopped = false;

    final String? scannedData = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: MobileScanner(
              onDetect: (capture) {
                if (isPopped) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  isPopped = true;
                  Navigator.of(context).pop(barcodes.first.rawValue);
                }
              },
            ),
          ),
        ),
      ),
    );

    if (scannedData != null) {
      try {
        String ip = scannedData;
        int port = 8000;

        if (scannedData.contains('|')) {
          final parts = scannedData.split('|');
          ip = parts[0];
          port = int.tryParse(parts[1]) ?? 8000;
        } else if (scannedData.contains(':')) {
          final parts = scannedData.split(':');
          ip = parts[0];
          port = int.tryParse(parts[1]) ?? 8000;
        }

        server.setManualIp(ip, port);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Invalid QR: $e'),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    }
  }

  Widget _buildConnectButtonChild(ServerStatus status) {
    switch (status) {
      case ServerStatus.searching:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: Colors.white,
          ),
        );
      case ServerStatus.connected:
        return const Text('Disconnect', style: TextStyle(color: Colors.redAccent));
      case ServerStatus.disconnected:
      default:
        return const Text('Connect', style: TextStyle(color: Colors.greenAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerProvider>();

    // SnackBar Logic
    if (server.status != _previousStatus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (server.status == ServerStatus.connected) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Connected to ${server.serverIp}'),
              backgroundColor: Colors.green,
            ));
          } else if (_previousStatus == ServerStatus.searching &&
              server.status == ServerStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Connection failed'),
              backgroundColor: Colors.redAccent,
            ));
          }
        }
      });
      _previousStatus = server.status;
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35.0,
        backgroundColor: Colors.black26,
        title: Row(
          children: [
            Icon(
              Icons.circle,
              color: server.status == ServerStatus.connected
                  ? Colors.green
                  : server.status == ServerStatus.searching
                      ? Colors.amber
                      : Colors.red,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getStatusMessage(server.status, server.serverIp),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: server.status == ServerStatus.searching
                ? null
                : () {
                    if (server.status == ServerStatus.connected) {
                      server.disconnect();
                      if (_selectedIndex == 1) _onItemTapped(0);
                    } else {
                      _showQRScannerDialog();
                    }
                  },
            child: _buildConnectButtonChild(server.status),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'Media'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getStatusMessage(ServerStatus status, String? ip) {
    switch (status) {
      case ServerStatus.connected:
        return 'Connected: $ip';
      case ServerStatus.searching:
        return 'Connecting...';
      case ServerStatus.found:
        return 'Found $ip';
      case ServerStatus.error:
        return 'Connection Error';
      case ServerStatus.disconnected:
      default:
        return 'Disconnected';
    }
  }
}
