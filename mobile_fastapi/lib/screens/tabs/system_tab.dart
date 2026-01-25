import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pc_provider.dart';

class SystemTab extends StatelessWidget {
  const SystemTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = context.read<PCProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('System Control')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PowerButton(
              title: 'Lock System',
              subtitle: 'Lock session immediately',
              icon: Icons.lock_outline,
              color: Colors.orange,
              onTap: pc.lockPC,
            ),
            const SizedBox(height: 16),
            _PowerButton(
              title: 'Sleep Mode',
              subtitle: 'Put the computer to sleep',
              icon: Icons.bedtime_outlined,
              color: Colors.indigoAccent,
              onTap: pc.sleepPC,
            ),
            const SizedBox(height: 16),
            _PowerButton(
              title: 'Shutdown',
              subtitle: 'Turn off the computer completely',
              icon: Icons.power_settings_new,
              color: Colors.redAccent,
              isDangerous: true,
              onTap: () => _confirmAction(context, 'Shutdown', pc.shutdownPC),
            ),
            const SizedBox(height: 40),
            const Text('Utilities', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            _PowerButton(
              title: 'Task Manager',
              subtitle: 'Open Windows Task Manager',
              icon: Icons.task_outlined,
              color: Colors.teal,
              onTap: pc.openTaskManager,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAction(BuildContext context, String action, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action?'),
        content: const Text('Are you sure you want to perform this action?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDangerous;

  const _PowerButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDangerous ? color.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
