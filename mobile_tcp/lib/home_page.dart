import 'dart:async';
import 'dart:convert'; // NEW: Need this for utf8.decode
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'connection_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<Uint8List>? _messageSubscription;
  ConnectionService? _connectionService;
  Timer? _commandTimer;

  String? _expandedCategoryKey;
  double _currentVolume = 50.0;
  bool _isConnected = false;

  // This variable will hold partial data chunks
  Uint8List? _buffer;

  // --- (Categories map is unchanged) ---
  final Map<String, Map<String, IconData>> _categories = {
    'POWER': {
      'LOCK': Icons.lock_outline_rounded,
      'SLEEP': Icons.power_settings_new_rounded,
      'SHUTDOWN': Icons.desktop_windows_rounded,
      'RESTART': Icons.restart_alt_rounded,
    },
    'VOLUME': {
      'MUTE': Icons.volume_off_rounded,
    },
    'MEDIA': {
      'PLAY_PAUSE': Icons.play_arrow_rounded,
      'NEXT': Icons.skip_next_rounded,
      'PREVIOUS': Icons.skip_previous_rounded,
    },
    'SYSTEM': {
      'TASK_MANAGER': Icons.table_chart_rounded,
      'SETTINGS': Icons.settings_rounded,
    },
  };
  final double _gridSpacing = 12.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectionService = Provider.of<ConnectionService>(context);
    _setupListener();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _commandTimer?.cancel();
    _buffer = null; // Clear the buffer
    super.dispose();
  }

  // --- COMPLETELY NEW LISTENER LOGIC ---
  void _setupListener() {
    _messageSubscription?.cancel();
    _buffer = null; // Clear buffer on new setup

    _messageSubscription = _connectionService?.socketStream?.listen(
          (data) {
        // 1. Add new data to our buffer
        if (_buffer == null) {
          _buffer = data;
        } else {
          _buffer = Uint8List.fromList(_buffer! + data);
        }

        // 2. Process all complete messages in the buffer
        _processBuffer();
      },
      onError: (error) {
        print("HomePage Listener Error: $error");
      },
      onDone: () {
        print("HomePage Listener: Stream done.");
        _buffer = null;
      },
    );
  }

  void _processBuffer() {
    if (_buffer == null || _buffer!.length < 4) {
      // Not enough data for a length header
      return;
    }

    // Read the 4-byte length header
    final length = ByteData.view(_buffer!.buffer).getUint32(0);

    // Check if we have the full message
    if (_buffer!.length < length + 4) {
      // Not enough data, wait for more
      return;
    }

    // We have a full message, extract it
    final payload = _buffer!.sublist(4, length + 4);

    // Remove this message from the buffer
    _buffer = _buffer!.sublist(length + 4);

    // --- Process the payload ---
    // This is the only part that's different from FilesPage
    try {
      final message = utf8.decode(payload).trim();
      print("HOMEPAGE: LISTENER: Received message: $message");

      // Check for our known commands
      if (message == 'OK') {
        _commandTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Command executed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (message.startsWith('VOLUME_IS ')) {
        _commandTimer?.cancel(); // Cancel the 'GET_VOLUME' timeout
        final parts = message.split(' ');
        if (parts.length == 2) {
          final volume = double.tryParse(parts[1]);
          if (volume != null) {
            setState(() {
              _currentVolume = volume;
              _expandedCategoryKey = 'VOLUME';
            });
          }
        }
      } else if (message.startsWith('ERROR:')) {
        _commandTimer?.cancel(); // Stop timer on error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
      // If it's not one of these, we assume it's a file list
      // intended for the FilesPage and we just ignore it.

    } catch (e) {
      // This was not text, probably a file download. Ignore it.
      print("HOMEPAGE: LISTENER: Received non-text data, ignoring.");
    }

    // --- Check for more messages ---
    // If there's still data in the buffer, process it
    if (_buffer != null && _buffer!.isNotEmpty) {
      _processBuffer();
    }
  }
  // --- END OF NEW LISTENER LOGIC ---

  // --- (All other methods and widgets are unchanged) ---
  // ... (send commands, build widgets, etc.) ...
  void _sendFireAndForgetCommand(String command) {
    if (_isConnected && _connectionService?.socket != null) {
      _connectionService!.socket!.write('$command\n');
    }
  }

  void _sendCommand(String command) {
    if (!_isConnected || _connectionService?.socket == null) return;
    _commandTimer?.cancel();
    _connectionService!.socket!.write('$command\n');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sent command: $command'),
        backgroundColor: Colors.blueAccent,
      ),
    );
    _commandTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server did not respond (timeout).'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  void _handleCategoryTap(String categoryKey) {
    if (!_isConnected) return;
    final bool isAlreadyExpanded = _expandedCategoryKey == categoryKey;
    if (isAlreadyExpanded) {
      setState(() {
        _expandedCategoryKey = null;
      });
    } else {
      if (categoryKey == 'VOLUME') {
        _sendCommand('GET_VOLUME');
      }
      else {
        setState(() {
          _expandedCategoryKey = categoryKey;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _isConnected =
        context.watch<ConnectionService>().connectionStatus ==
            ConnectionStatus.connected;

    return ListView(
      padding: EdgeInsets.all(_gridSpacing),
      children: _categories.entries.map((category) {
        final String categoryKey = category.key;
        final Map<String, IconData> commands = category.value;
        final bool isExpanded = _expandedCategoryKey == categoryKey;
        return _buildExpandableCategory(
          categoryKey: categoryKey,
          commands: commands,
          isExpanded: isExpanded,
          isConnected: _isConnected,
        );
      }).toList(),
    );
  }

  Widget _buildExpandableCategory({
    required String categoryKey,
    required Map<String, IconData> commands,
    required bool isExpanded,
    required bool isConnected,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCategoryRow(
          categoryKey: categoryKey,
          isExpanded: isExpanded,
          isConnected: isConnected,
          onTap: () => _handleCategoryTap(categoryKey),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: Container(
            child: !isExpanded
                ? const SizedBox.shrink()
                : categoryKey == 'VOLUME'
                ? _buildVolumeSlider(isConnected: isConnected)
                : _buildExpansionGrid(
              commands: commands,
              isConnected: isConnected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow({
    required String categoryKey,
    required bool isExpanded,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    final Color color = isConnected ? Colors.white : Colors.grey[700]!;
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        onTap: isConnected ? onTap : null,
        title: Text(
          categoryKey,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        trailing: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({required bool isConnected}) {
    final bool isEnabled = isConnected;
    final Color effectiveColor = isEnabled ? Colors.white : Colors.grey[700]!;
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 8.0, right: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.volume_off_rounded,
              color: effectiveColor,
              size: 30,
            ),
            onPressed: !isEnabled ? null : () => _sendCommand('MUTE'),
          ),
          Expanded(
            child: Slider(
              value: _currentVolume,
              min: 0,
              max: 100,
              divisions: 100,
              label: _currentVolume.round().toString(),
              activeColor: effectiveColor,
              inactiveColor: Colors.grey[700],
              onChanged: !isEnabled
                  ? null
                  : (double value) {
                setState(() {
                  _currentVolume = value;
                });
                _sendFireAndForgetCommand(
                    'SET_VOLUME_LIVE ${value.round()}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpansionGrid({
    required Map<String, IconData> commands,
    required bool isConnected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: _gridSpacing,
        crossAxisSpacing: _gridSpacing,
        childAspectRatio: 1.0,
        children: commands.entries.map((entry) {
          return _buildCommandTile(
            command: entry.key,
            icon: entry.value,
            isConnected: isConnected,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCommandTile({
    required String command,
    required IconData icon,
    required bool isConnected,
  }) {
    final bool isEnabled = isConnected;
    final Color effectiveColor = isEnabled ? Colors.white : Colors.grey[700]!;
    final Color tileColor = isEnabled ? Colors.grey[850]! : Colors.grey[900]!;
    return Card(
      elevation: isEnabled ? 4.0 : 1.0,
      color: tileColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: !isEnabled ? null : () => _sendCommand(command),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: effectiveColor),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  command,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: effectiveColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}