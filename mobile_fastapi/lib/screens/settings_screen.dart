import 'package:flutter/material.dart';
import '../services/connection_provider.dart';
import 'home_screen.dart';

class SettingsScreen extends StatelessWidget {
  final ConnectionProvider conn;
  const SettingsScreen({super.key, required this.conn});

  @override
  Widget build(BuildContext context) {
    final server = conn.server;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),

        // Server Info
        _sectionLabel('SERVER INFO'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoRow('Name', server?.name ?? '—'),
                const SizedBox(height: 12),
                _infoRow('IP Address', server?.ip ?? '—'),
                const SizedBox(height: 12),
                _infoRow('Port', server?.port.toString() ?? '—'),
                const SizedBox(height: 12),
                _infoRow('Status', conn.isConnected ? 'Connected' : 'Disconnected'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Actions
        _sectionLabel('ACTIONS'),
        const SizedBox(height: 12),

        Card(
          child: ListTile(
            leading: const Icon(Icons.link_off_rounded, color: Color(0xFFF85149)),
            title: const Text('Unpair Device'),
            subtitle: Text(
              'Removes saved API key and disconnects',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            ),
            onTap: () => _showUnpairDialog(context),
          ),
        ),

        const SizedBox(height: 40),

        // App info
        Center(
          child: Text(
            'PC Remote v2.0.0',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  void _showUnpairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2128),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unpair Device?'),
        content: const Text('This will remove the saved API key. You\'ll need to scan the QR code again to reconnect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF85149)),
            onPressed: () async {
              Navigator.pop(ctx);
              await conn.unpair();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
  }
}
