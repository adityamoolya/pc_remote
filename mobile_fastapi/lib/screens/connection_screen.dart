import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/server_provider.dart';
import '../providers/pc_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              const Color(0xFF0F1016),
            ],
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(_scanController),
                      child: Icon(
                        Icons.radar,
                        size: 64,
                        color: Theme.of(context).primaryColor,
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
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // --- Discovery Status ---
                  if (server.status == ServerStatus.found)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                server.pcName ?? 'Unknown PC',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${server.serverIp}:${server.serverPort}'),
                            ],
                          ),
                        ],
                      ),
                    ),

                  // --- Action Buttons ---
                  if (!_showManual) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isScanning ? null : () => server.discover(),
                        icon: isScanning 
                            ? Container(
                                width: 24, 
                                height: 24, 
                                padding: const EdgeInsets.all(2),
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
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
                        color: Theme.of(context).cardTheme.color,
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
                            obscureText: true,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: context.watch<PCProvider>().isLoading ? null : _handleConnect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                              ),
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
                                child: const Text('Cancel Manual Entry'),
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
