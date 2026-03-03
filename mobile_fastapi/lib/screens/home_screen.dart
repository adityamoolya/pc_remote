import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_provider.dart';
import 'qr_scanner_sheet.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionProvider>(
      builder: (context, conn, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF58A6FF), Color(0xFF3FB950)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.desktop_windows_rounded, size: 28, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PC Remote',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            conn.statusMessage,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Status indicator
                  if (conn.state == AppConnectionState.discovering) ...[
                    _buildDiscoveringSection(context, conn),
                  ] else if (conn.state == AppConnectionState.disconnected) ...[
                    _buildDisconnectedSection(context, conn),
                  ],

                  // Server list
                  if (conn.discoveredServers.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'AVAILABLE DEVICES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: conn.discoveredServers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final server = conn.discoveredServers[index];
                          return _buildServerCard(context, conn, server);
                        },
                      ),
                    ),
                  ] else if (conn.state == AppConnectionState.discovering) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Scanning for your PC...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Make sure the server is running\nand you\'re on the same Wi-Fi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscoveringSection(BuildContext context, ConnectionProvider conn) {
    return const SizedBox.shrink();
  }

  Widget _buildDisconnectedSection(BuildContext context, ConnectionProvider conn) {
    return Center(
      child: TextButton.icon(
        onPressed: () => conn.startDiscovery(),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry Discovery'),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, ConnectionProvider conn, DiscoveredServer server) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleServerTap(context, conn, server),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF58A6FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.computer_rounded,
                  color: Color(0xFF58A6FF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${server.ip}:${server.port}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                conn.hasSavedKey ? Icons.link_rounded : Icons.qr_code_scanner_rounded,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleServerTap(BuildContext context, ConnectionProvider conn, DiscoveredServer server) async {
    if (!conn.hasSavedKey) {
      // No saved key → open QR scanner
      final scannedKey = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const QRScannerSheet(),
      );

      if (scannedKey != null && scannedKey.isNotEmpty) {
        await conn.saveApiKey(scannedKey);
      } else {
        return; // User cancelled
      }
    }

    // Try connecting
    if (!context.mounted) return;
    final success = await conn.connectToServer(server);
    if (success && context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to connect. Check your API key.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Re-scan',
            textColor: Colors.white,
            onPressed: () async {
              await conn.unpair();
              if (context.mounted) {
                _handleServerTap(context, conn, server);
              }
            },
          ),
        ),
      );
    }
  }
}
