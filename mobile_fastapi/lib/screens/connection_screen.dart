import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../providers/pc_provider.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '8080');
  final TextEditingController _keyController = TextEditingController();
  bool _showManual = false;
  bool _attemptingAutoLogin = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    // Attempt auto-login with stored credentials
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLogin();
    });
  }

  Future<void> _attemptAutoLogin() async {
    final server = context.read<ServerProvider>();
    
    if (server.autoLoginAttempted) return;
    server.markAutoLoginAttempted();
    
    await server.loadStoredCredentials();
    
    if (server.hasStoredCredentials && mounted) {
      setState(() => _attemptingAutoLogin = true);
      
      final pc = context.read<PCProvider>();
      final success = await pc.verifyConnection();
      
      if (success && mounted) {
        server.markConnected();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      } else {
        // Clear invalid credentials
        await server.clearStoredCredentials();
        if (mounted) {
          setState(() => _attemptingAutoLogin = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved credentials expired. Please reconnect.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  void _handleConnect() async {
    final server = context.read<ServerProvider>();
    final pc = context.read<PCProvider>();

    if (_showManual) {
      server.setManualIp(_ipController.text, int.tryParse(_portController.text) ?? 8080);
    }
    
    server.setApiKey(_keyController.text);

    final success = await pc.verifyConnection();
    if (success) {
      server.markConnected();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Failed: ${pc.lastError}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerProvider>();
    final isScanning = server.status == ServerStatus.searching;

    if (isScanning && !_scanController.isAnimating) {
      _scanController.repeat();
    } else if (!isScanning && _scanController.isAnimating) {
      _scanController.stop();
      _scanController.reset();
    }

    // Show loading while attempting auto-login
    if (_attemptingAutoLogin) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                'Reconnecting...',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.background, Color(0xFF060608)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- Logo / Icon ---
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary.withAlpha(128),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(51),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(_scanController),
                      child: const Icon(
                        Icons.radar,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Title ---
                  Text(
                    'PC Remote',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Control your PC from anywhere',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // --- Discovery Status ---
                  if (server.status == ServerStatus.found)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.success.withAlpha(76)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.success),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.pcName ?? 'PC Found',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${server.serverIp}:${server.serverPort}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // --- Action Buttons ---
                  if (!_showManual && server.status != ServerStatus.found) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isScanning ? null : () => server.discover(),
                        icon: isScanning 
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: Padding(
                                  padding: EdgeInsets.all(2),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(isScanning ? 'Scanning...' : 'Scan Network'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => setState(() => _showManual = true),
                      child: const Text('Enter IP Manually'),
                    ),
                  ],

                  // --- Manual Entry Form ---
                  if (_showManual || server.status == ServerStatus.found) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          if (_showManual) ...[
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _ipController,
                                    decoration: const InputDecoration(
                                      labelText: 'IP Address',
                                      prefixIcon: Icon(Icons.wifi),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: _portController,
                                    decoration: const InputDecoration(
                                      labelText: 'Port',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _keyController,
                            decoration: const InputDecoration(
                              labelText: 'Pairing Code',
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: context.watch<PCProvider>().isLoading ? null : _handleConnect,
                              child: context.watch<PCProvider>().isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Connect'),
                            ),
                          ),
                          if (_showManual) 
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: TextButton(
                                onPressed: () => setState(() => _showManual = false),
                                child: const Text('Cancel'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
