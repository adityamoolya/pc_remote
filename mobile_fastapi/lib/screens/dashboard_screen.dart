import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/connection_provider.dart';
import 'file_explorer_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    if (!conn.isConnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
      return const SizedBox.shrink();
    }

    final pages = [
      _ControlsTab(conn: conn),
      FileExplorerScreen(api: conn.api),
      SettingsScreen(conn: conn),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tabIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        backgroundColor: const Color(0xFF0D1117),
        indicatorColor: const Color(0xFF58A6FF).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.gamepad_rounded), label: 'Controls'),
          NavigationDestination(icon: Icon(Icons.folder_rounded), label: 'Files'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── Controls Tab ───
class _ControlsTab extends StatefulWidget {
  final ConnectionProvider conn;
  const _ControlsTab({required this.conn});

  @override
  State<_ControlsTab> createState() => _ControlsTabState();
}

class _ControlsTabState extends State<_ControlsTab> {
  double _volume = 50;
  bool _volumeLoaded = false;
  bool _isMuted = false;
  WebSocketChannel? _wsChannel;

  @override
  void initState() {
    super.initState();
    _loadVolume();
    _connectVolumeWs();
  }

  @override
  void dispose() {
    _wsChannel?.sink.close();
    super.dispose();
  }

  Future<void> _loadVolume() async {
    final vol = await widget.conn.api.getVolume();
    if (vol != null && mounted) {
      setState(() {
        _volume = vol.toDouble();
        _volumeLoaded = true;
      });
    }
  }

  void _connectVolumeWs() {
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(widget.conn.api.wsVolumeUrl));
    } catch (_) {}
  }

  void _onVolumeChanged(double val) {
    setState(() => _volume = val);
    widget.conn.api.updateVolumeCache(val.round());
    _wsChannel?.sink.add(val.round().toString());
  }

  Future<void> _doAction(String type, String action, String label) async {
    bool ok;
    if (type == 'system') {
      ok = await widget.conn.api.systemAction(action);
    } else {
      ok = await widget.conn.api.mediaAction(action);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '$label sent' : '$label failed'),
        backgroundColor: ok ? const Color(0xFF3FB950) : const Color(0xFFF85149),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Text(
          'Controls',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.conn.server?.name ?? 'PC',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
        ),
        const SizedBox(height: 28),

        // ─── Media Section ───
        _sectionLabel('MEDIA'),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(Icons.skip_previous_rounded, 'Previous', () => _doAction('media', 'prev', 'Previous')),
            const SizedBox(width: 20),
            _circleButton(Icons.play_arrow_rounded, 'Play', () => _doAction('media', 'playpause', 'Play/Pause'), large: true),
            const SizedBox(width: 20),
            _circleButton(Icons.skip_next_rounded, 'Next', () => _doAction('media', 'next', 'Next')),
          ],
        ),
        const SizedBox(height: 28),

        // ─── Volume Section ───
        _sectionLabel('VOLUME'),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: const Color(0xFF58A6FF),
                  ),
                  onPressed: () async {
                    final ok = await widget.conn.api.mediaAction('mute');
                    if (ok && mounted) setState(() => _isMuted = !_isMuted);
                  },
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF58A6FF),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                      thumbColor: const Color(0xFF58A6FF),
                      overlayColor: const Color(0xFF58A6FF).withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _volumeLoaded ? _volume : 50,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _volume.round().toString(),
                      onChanged: _volumeLoaded ? _onVolumeChanged : null,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${_volume.round()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ─── Power Section ───
        _sectionLabel('POWER'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: [
            _actionCard(Icons.lock_rounded, 'Lock', () => _doAction('system', 'lock', 'Lock')),
            _actionCard(Icons.power_settings_new_rounded, 'Sleep', () => _doAction('system', 'sleep', 'Sleep')),
            _actionCard(Icons.desktop_windows_rounded, 'Shutdown', () => _doAction('system', 'shutdown', 'Shutdown')),
            _actionCard(Icons.table_chart_rounded, 'Task Mgr', () => _doAction('system', 'taskmanager', 'Task Manager')),
          ],
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

  Widget _circleButton(IconData icon, String label, VoidCallback onTap, {bool large = false}) {
    final size = large ? 64.0 : 50.0;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: large
                  ? const LinearGradient(
                      colors: [Color(0xFF58A6FF), Color(0xFF388BFD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: large ? null : Colors.white.withValues(alpha: 0.06),
              border: large ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, size: large ? 30 : 24, color: Colors.white),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF58A6FF)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
