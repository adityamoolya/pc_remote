import 'package:flutter/material.dart';
import '../services/discovery_service.dart';
import '../services/api_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final DiscoveryService _discovery = DiscoveryService();
  final ApiService _api = ApiService();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _pathController = TextEditingController(text: 'C:\\');

  String _serverStatus = 'Not connected';
  String _serverIp = '';
  int _serverPort = 0;
  String _log = '';
  bool _isDiscovering = false;
  double _volume = 50;

  void _addLog(String message) {
    setState(() {
      _log = '${DateTime.now().toString().substring(11, 19)} | $message\n$_log';
    });
  }

  Future<void> _discover() async {
    setState(() {
      _isDiscovering = true;
      _serverStatus = 'Searching...';
    });

    final result = await _discovery.discoverServer();

    setState(() {
      _isDiscovering = false;
      if (result != null) {
        _serverIp = result['ip'] ?? '';
        _serverPort = result['port'] ?? 0;
        _serverStatus = 'Found: $_serverIp:$_serverPort';
        _addLog('Server discovered: ${result['pcName']} at $_serverIp:$_serverPort');
      } else {
        _serverStatus = 'Not found (timeout)';
        _addLog('Discovery failed - no server found');
      }
    });
  }

  Future<void> _connect() async {
    if (_serverIp.isEmpty) {
      _addLog('ERROR: No server IP. Run discovery first or enter IP manually.');
      return;
    }
    if (_apiKeyController.text.isEmpty) {
      _addLog('ERROR: Please enter the API key');
      return;
    }
    
    _api.configure(
      ip: _serverIp,
      port: _serverPort,
      apiKey: _apiKeyController.text,
    );
    _addLog('Configured: $_serverIp:$_serverPort with key ${_apiKeyController.text}');
    
    // Test connection with an authenticated endpoint to verify API key
    try {
      final result = await _api.getVolume(); // This requires auth
      setState(() {
        _serverStatus = 'Connected ✓ (Auth OK)';
      });
      _addLog('Auth verified! Volume: ${result['level']}%');
    } catch (e) {
      setState(() {
        _serverStatus = 'Auth failed ✗';
      });
      _addLog('Auth FAILED: $e (check API key)');
    }
  }

  Future<void> _callApi(String name, Future<Map<String, dynamic>> Function() call) async {
    if (!_api.isConfigured) {
      _addLog('ERROR: Not configured. Enter API key and connect first.');
      return;
    }
    try {
      final result = await call();
      _addLog('$name: $result');
    } catch (e) {
      _addLog('$name ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Remote - API Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === CONNECTION SECTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Status: $_serverStatus'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isDiscovering ? null : _discover,
                            icon: _isDiscovering
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('Discover'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _connect,
                            icon: const Icon(Icons.link),
                            label: const Text('Connect'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Server IP',
                              hintText: _serverIp.isEmpty ? '192.168.x.x' : _serverIp,
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => _serverIp = v,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Port',
                              hintText: _serverPort == 0 ? '8080' : '$_serverPort',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _serverPort = int.tryParse(v) ?? 8080,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        hintText: 'Enter the pairing code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === SYSTEM SECTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _callApi('Health', _api.healthCheck),
                          child: const Text('Health'),
                        ),
                        ElevatedButton(
                          onPressed: () => _callApi('Lock', _api.lock),
                          child: const Text('Lock'),
                        ),
                        ElevatedButton(
                          onPressed: () => _callApi('Task Manager', _api.taskManager),
                          child: const Text('Task Mgr'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          onPressed: () => _callApi('Sleep', _api.sleep),
                          child: const Text('Sleep'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => _callApi('Shutdown', _api.shutdown),
                          child: const Text('Shutdown'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === FILES SECTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Files', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _callApi('Drives', _api.getDrives),
                          child: const Text('Get Drives'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _pathController,
                            decoration: const InputDecoration(
                              labelText: 'Path',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _callApi('List', () => _api.listFiles(_pathController.text)),
                          child: const Text('List'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === MEDIA SECTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            await _callApi('Get Volume', _api.getVolume);
                          },
                          child: const Text('Get Vol'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${_volume.toInt()}%',
                            onChanged: (v) => setState(() => _volume = v),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _callApi('Set Volume', () => _api.setVolume(_volume.toInt())),
                          child: const Text('Set'),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => _callApi('Play/Pause', _api.playPause),
                      child: const Text('Play/Pause'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === LOG SECTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Response Log', style: Theme.of(context).textTheme.titleMedium),
                        TextButton(
                          onPressed: () => setState(() => _log = ''),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _log.isEmpty ? 'No logs yet...' : _log,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _pathController.dispose();
    super.dispose();
  }
}
