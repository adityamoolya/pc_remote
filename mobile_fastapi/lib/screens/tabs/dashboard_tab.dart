import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/server_provider.dart';
import '../../providers/pc_provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String? _expandedCategoryKey;
  final double _gridSpacing = 12.0;

  // Categories map matches mobile_tcp
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

  @override
  void initState() {
    super.initState();
    // Refresh volume on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (mounted) context.read<PCProvider>().refreshVolume();
    });
  }

  void _handleCategoryTap(String categoryKey) {
    // Only allow interaction if connected? mobile_tcp checked connection.
    // Provider check
    final isConnected = context.read<ServerProvider>().status == ServerStatus.connected;
    if (!isConnected) return;

    final bool isAlreadyExpanded = _expandedCategoryKey == categoryKey;
    if (isAlreadyExpanded) {
      setState(() {
        _expandedCategoryKey = null;
      });
    } else {
      if (categoryKey == 'VOLUME') {
        context.read<PCProvider>().refreshVolume();
      }
      setState(() {
        _expandedCategoryKey = categoryKey;
      });
    }
  }

  void _sendCommand(String command, PCProvider pc) {
    // Map commands to PCProvider methods
    switch (command) {
      case 'LOCK': pc.lockPC(); break;
      case 'SLEEP': pc.sleepPC(); break;
      case 'SHUTDOWN': pc.shutdownPC(); break;
      // case 'RESTART': pc.restartPC(); break; // basic provider might missing this
      case 'MUTE': pc.mediaControl('mute'); break;
      case 'PLAY_PAUSE': pc.mediaControl('playpause'); break;
      case 'NEXT': pc.mediaControl('next'); break; 
      case 'PREVIOUS': pc.mediaControl('previous'); break;
      case 'TASK_MANAGER': pc.openTaskManager(); break;
      default:
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Command $command not yet implemented in FastAPI provider'),
          duration: const Duration(seconds: 1),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = context.watch<ServerProvider>();
    // final pc = context.watch<PCProvider>(); // access in callbacks or sub-widgets
    final isConnected = server.status == ServerStatus.connected;

    // We can use the same layout as mobile_tcp: ListView of Categories
    return Scaffold(
      appBar: AppBar(
         title: const Text('Dashboard'),
         automaticallyImplyLeading: false,
         elevation: 0,
         backgroundColor: Colors.transparent, 
      ),
      body: ListView(
        padding: EdgeInsets.all(_gridSpacing),
        children: _categories.entries.map((category) {
          final String categoryKey = category.key;
          final Map<String, IconData> commands = category.value;
          final bool isExpanded = _expandedCategoryKey == categoryKey;
          return _buildExpandableCategory(
            categoryKey: categoryKey,
            commands: commands,
            isExpanded: isExpanded,
            isConnected: isConnected,
          );
        }).toList(),
      ),
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
    final pc = context.watch<PCProvider>();
    final bool isEnabled = isConnected;
    final Color effectiveColor = isEnabled ? Colors.white : Colors.grey[700]!;
    
    // Safety check for volume
    final double currentVolume = (pc.volume).clamp(0, 100).toDouble();

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
            onPressed: !isEnabled ? null : () => pc.mediaControl('mute'),
          ),
          Expanded(
            child: Slider(
              value: currentVolume,
              min: 0,
              max: 100,
              divisions: 100,
              label: currentVolume.round().toString(),
              activeColor: effectiveColor,
              inactiveColor: Colors.grey[700],
              onChanged: !isEnabled
                  ? null
                  : (double value) {
                // Optimistic update in provider
                pc.setVolume(value.round());
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
        onTap: !isEnabled ? null : () {
           // Send command
           _sendCommand(command, context.read<PCProvider>());
        },
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
