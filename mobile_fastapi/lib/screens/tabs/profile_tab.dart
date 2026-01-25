import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';
import '../../theme/app_theme.dart';
import '../connection_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- Connection Status Card ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: server.isConnected 
                          ? AppTheme.success.withAlpha(25)
                          : Colors.red.withAlpha(25),
                      border: Border.all(
                        color: server.isConnected ? AppTheme.success : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      server.isConnected ? Icons.computer : Icons.power_off,
                      size: 40,
                      color: server.isConnected ? AppTheme.success : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    server.pcName ?? 'Unknown PC',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    server.isConnected 
                        ? '${server.serverIp}:${server.serverPort}'
                        : 'Not Connected',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: server.isConnected 
                          ? AppTheme.success.withAlpha(25)
                          : Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      server.isConnected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: server.isConnected ? AppTheme.success : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Info Tiles ---
            _InfoTile(
              icon: Icons.key,
              title: 'API Key',
              value: server.apiKey.isNotEmpty 
                  ? '••••${server.apiKey.substring(server.apiKey.length - 4)}'
                  : 'Not set',
            ),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.network_wifi,
              title: 'Connection Type',
              value: 'Local Network',
            ),
            
            const SizedBox(height: 40),

            // --- Disconnect Button ---
            if (server.isConnected)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    server.disconnect();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const ConnectionScreen()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.power_settings_new),
                  label: const Text('Disconnect'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
