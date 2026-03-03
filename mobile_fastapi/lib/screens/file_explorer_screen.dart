import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/file_item.dart';
import '../services/api_service.dart';

class FileExplorerScreen extends StatefulWidget {
  final ApiService api;
  const FileExplorerScreen({super.key, required this.api});

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  bool _loading = true;
  String? _error;
  String _currentPath = 'Drives';
  List<FileItem> _items = [];
  final List<String> _pathHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchDrives();
  }

  Future<void> _fetchDrives() async {
    setState(() { _loading = true; _error = null; });
    final drives = await widget.api.getDrives();
    if (drives != null && mounted) {
      setState(() {
        _items = drives;
        _currentPath = 'Drives';
        _loading = false;
      });
    } else if (mounted) {
      setState(() { _error = 'Failed to load drives'; _loading = false; });
    }
  }

  Future<void> _fetchDir(String path) async {
    setState(() { _loading = true; _error = null; });
    final items = await widget.api.listFiles(path);
    if (items != null && mounted) {
      setState(() {
        _pathHistory.add(_currentPath);
        _items = items;
        _currentPath = path;
        _loading = false;
      });
    } else if (mounted) {
      setState(() { _error = 'Failed to load directory'; _loading = false; });
    }
  }

  void _navigateBack() {
    if (_pathHistory.isEmpty) return;
    final prev = _pathHistory.removeLast();
    if (prev == 'Drives') {
      _fetchDrives();
    } else {
      // Direct fetch without adding to history
      setState(() { _loading = true; _error = null; });
      widget.api.listFiles(prev).then((items) {
        if (items != null && mounted) {
          setState(() { _items = items; _currentPath = prev; _loading = false; });
        }
      });
    }
  }

  Future<void> _downloadFile(FileItem item) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${item.name}...'), duration: const Duration(seconds: 1)),
    );

    final data = await widget.api.downloadFile(item.path);
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed'), backgroundColor: Color(0xFFF85149)),
        );
      }
      return;
    }

    // Save to downloads
    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();

    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${item.name}');
    await file.writeAsBytes(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${item.name}'), backgroundColor: const Color(0xFF3FB950)),
      );
    }
  }

  IconData _iconFor(FileItemType type) {
    switch (type) {
      case FileItemType.drive: return Icons.storage_rounded;
      case FileItemType.folder: return Icons.folder_rounded;
      case FileItemType.file: return Icons.description_outlined;
      case FileItemType.up: return Icons.arrow_upward_rounded;
    }
  }

  Color _iconColor(FileItemType type) {
    switch (type) {
      case FileItemType.drive: return const Color(0xFF58A6FF);
      case FileItemType.folder: return const Color(0xFFD29922);
      case FileItemType.file: return Colors.white.withValues(alpha: 0.5);
      case FileItemType.up: return Colors.white.withValues(alpha: 0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              if (_currentPath != 'Drives')
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  onPressed: _navigateBack,
                  color: Colors.white.withValues(alpha: 0.7),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (_currentPath != 'Drives') const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentPath == 'Drives' ? 'My Computer' : _currentPath.replaceAll('\\', ' › '),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _currentPath == 'Drives' ? _fetchDrives : () => _fetchDir(_currentPath),
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _currentPath == 'Drives' ? _fetchDrives : () => _fetchDir(_currentPath),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Empty folder',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            leading: Icon(_iconFor(item.type), color: _iconColor(item.type)),
            title: Text(
              item.name,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: item.type == FileItemType.folder || item.type == FileItemType.drive
                ? Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20)
                : IconButton(
                    icon: Icon(Icons.download_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
                    onPressed: () => _downloadFile(item),
                  ),
            onTap: () {
              if (item.type == FileItemType.folder || item.type == FileItemType.drive) {
                _fetchDir(item.path);
              }
            },
          ),
        );
      },
    );
  }
}
