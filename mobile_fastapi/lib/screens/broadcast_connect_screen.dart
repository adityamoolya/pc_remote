import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_provider.dart';
import 'connection_mode_screen.dart';
import 'qr_scanner_sheet.dart';
import 'dashboard_screen.dart';

class BroadcastConnectScreen extends StatefulWidget {
  const BroadcastConnectScreen({super.key});

  @override
  State<BroadcastConnectScreen> createState() => _BroadcastConnectScreenState();
}

class _BroadcastConnectScreenState extends State<BroadcastConnectScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    final conn = context.read<ConnectionProvider>();
    final url = _urlController.text.trim();

    // Ensure we have an API key
    String? apiKey = conn.apiKey;
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await _getApiKey();
      if (apiKey == null || apiKey.isEmpty) return; // user cancelled
    }

    setState(() => _isConnecting = true);

    final success = await conn.connectBroadcast(url, apiKey);

    if (!mounted) return;
    setState(() => _isConnecting = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to connect. Check the URL and API key.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _getApiKey() async {
    // Try QR scanner first
    final scannedKey = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QRScannerSheet(),
    );
    return scannedKey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header with back
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const ConnectionModeScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3FB950), Color(0xFF2EA043)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.public_rounded,
                        size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Broadcast Mode',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Connect via Cloudflare tunnel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // URL input
              Text(
                'SERVER URL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'https://xxxx.trycloudflare.com',
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.25)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    prefixIcon: Icon(Icons.link_rounded,
                        color: Colors.white.withValues(alpha: 0.4)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFF3FB950), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0xFFF85149)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    if (!value.trim().startsWith('https://')) {
                      return 'URL must start with https://';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Paste the Cloudflare tunnel URL from your PC server',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 36),

              // Connect button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isConnecting ? null : _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3FB950),
                    disabledBackgroundColor:
                        const Color(0xFF3FB950).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isConnecting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const Spacer(),
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 20,
                        color: Colors.white.withValues(alpha: 0.3)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Run cloudflared tunnel on your PC and paste the generated URL above.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
