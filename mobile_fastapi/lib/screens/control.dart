import 'package:flutter/material.dart';
import '../scripts/api_service.dart';

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});

  @override
  State<ControlsScreen> createState() => _ControlsScreenState();
}

class _ControlsScreenState extends State<ControlsScreen> {
  final ApiService _api = ApiService(); // Singleton access
  double _currentValue = 50;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Helper to send commands and keep UI code clean.
  /// Assumes you added a generic `post(path, data)` to your ApiService.
  void _send(String endpoint, [Map<String, dynamic>? data]) {
    // If you haven't added a generic post method to ApiService yet,
    // you can implement it there, or call specific methods like _api.lockPc()
    _api.post(endpoint, data);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // --- Row 1: Power Controls ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _send('/system/lock'),
                child: const Text('Lock PC'),
              ),
              ElevatedButton(
                onPressed: () => _send('/system/sleep'),
                child: const Text('Sleep PC'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100, // Visual cue for danger
                  foregroundColor: Colors.red,
                ),
                onPressed: () => _send('/system/shutdown'),
                child: const Text('Shutdown'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Row 2: Utility ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _send('/system/taskmgr'),
                child: const Text('Task Mgr'),
              ),
              ElevatedButton(
                onPressed: () => _send('/media/playpause'),
                child: const Text('Play/Pause'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Row 3: Volume Slider ---
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.volume_up, color: Colors.white),
                Expanded(
                  child: Slider(
                    value: _currentValue,
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: _currentValue.round().toString(),
                    onChanged: (val) => setState(() => _currentValue = val),
                    // Critical: Use onChangeEnd to send request only when user lets go
                    onChangeEnd: (val) => _send('/media/volume', {'level': val.toInt()}),
                  ),
                ),
                Text(
                  '${_currentValue.round()}%',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Row 4: Text Input ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type on PC...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    _send('/keyboard/type', {'text': _controller.text});
                    _controller.clear();
                  }
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}