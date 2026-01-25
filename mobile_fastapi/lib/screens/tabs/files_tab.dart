import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import '../../providers/server_provider.dart';
import '../../providers/pc_provider.dart';

class FilesTab extends StatefulWidget {
  const FilesTab({super.key});

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> {
  String _currentPath = "Drives";
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<ServerProvider>().status == ServerStatus.connected) {
         _loadDrives();
      }
    });
  }

  Future<void> _loadDrives() async {
    setState(() {
      _isLoading = true; 
      _currentPath = "Drives";
      _error = null;
    });
    try {
      final pc = context.read<PCProvider>();
      await pc.fetchDrives();
      setState(() {
        _items = pc.drives.map((d) => {'name': d, 'type': 'drive', 'path': d}).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPath(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
      _error = null;
    });
    try {
      final pc = context.read<PCProvider>();
      final items = await pc.listFiles(path);
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
         setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _navigateUp() {
    if (_currentPath == "Drives" || _currentPath.isEmpty) return;
    
    // Check if we are at root (e.g. C:\)
    // Windows path logic
    if (_currentPath.endsWith(':\\') || _currentPath.endsWith(':/') || 
        (_currentPath.length == 3 && _currentPath.endsWith(':'))) {
      _loadDrives();
      return;
    }
    
    // Very basic parent logic using 'path' package if possible or string manipulation
    // The server path separator might be different from client. 
    // Assuming backend returns paths with standard slashes or backslashes.
    // Let's try to use string manipulation to be safe with mixed separators
    
    String parent = p.dirname(_currentPath);
    if (parent == '.' || parent == _currentPath) {
       _loadDrives();
    } else {
       _loadPath(parent);
    }
  }

  Future<void> _downloadFile(Map<String, dynamic> item) async {
    // Permission check
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    // Android 13+ usually has photos/videos/audio permissions, or manage external storage
    // Permission.storage might be restricted.
    // Basic check for now.
    
    // if (status.isPermanentlyDenied) { ... }

    Directory? dir = await getDownloadsDirectory();
    if (dir == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Could not find Downloads directory."),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final filename = item['name'] ?? 'download';
    final savePath = p.join(dir.path, filename);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Downloading $filename..."),
    ));

    try {
      final pc = context.read<PCProvider>();
      // Construct full path for download if 'path' key is missing or relative?
      // listFiles returns full path usually? Or we construct it.
      // _loadPath sets _currentPath. Item usually has just 'name'.
      // Wait, listFiles in PCProvider returns whatever API returns.
      // API listFiles usually returns item list.
      // If item doesn't have 'path', we join _currentPath + name.
      
      String itemPath = item['path'];
      if (itemPath == null || itemPath.isEmpty) {
        // Construct it
        // Handle separator
         final separator = _currentPath.endsWith('\\') || _currentPath.endsWith('/') ? '' : '\\';
         itemPath = '$_currentPath$separator${item['name']}';
      }

      await pc.downloadFile(itemPath, savePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Saved to $savePath"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  IconData _getIcon(String type, bool isDir) {
    if (type == 'drive') return Icons.storage_rounded;
    if (isDir) return Icons.folder_rounded;
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<ServerProvider>().status != ServerStatus.connected) {
       return const Center(child: Text('Not Connected.'));
    }

    return Column(
      children: [
        // --- Path Header ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.black26,
          child: Row(
            children: [
              if (_currentPath != 'Drives')
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                  onPressed: _navigateUp,
                  tooltip: 'Go up',
                ),
              Expanded(
                child: Text(
                  _currentPath == "Drives" ? "My Computer" : _currentPath,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
               if (_currentPath != 'Drives' && !_isLoading)
                IconButton(
                   icon: const Icon(Icons.refresh, color: Colors.white70),
                   onPressed: () => _loadPath(_currentPath),
                )
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: $_error', style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _loadDrives, child: const Text("Retry"))
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isDrive = item['type'] == 'drive';
                        final isDir = isDrive || item['is_dir'] == true;
                        final name = item['name'] ?? 'Unknown';
                        // Construct path if needed, but for tapping we just need name usually for folders
                        
                        // Card style from mobile_tcp
                        final card = Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                          color: Colors.grey[850],
                          child: ListTile(
                            leading: Icon(_getIcon(item['type'] ?? 'file', isDir), color: isDrive ? Colors.blueAccent : Colors.white),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: isDir 
                                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey)
                                : null,
                            onTap: () {
                              if (isDrive) {
                                _loadPath(item['name']); // Drive name is path like "C:\"
                              } else if (isDir) {
                                // Join path
                                final separator = _currentPath.endsWith('\\') || _currentPath.endsWith('/') ? '' : '\\';
                                _loadPath('$_currentPath$separator$name');
                              } else {
                                // File tap - maybe generic open? or just toast
                                ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text('Swipe left to download $name')),
                                );
                              }
                            },
                          ),
                        );

                        if (isDir) return card;

                        return Dismissible(
                          key: Key('${_currentPath}_$name'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerRight,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text("Download", style: TextStyle(color: Colors.white)),
                                SizedBox(width: 8),
                                Icon(Icons.download_rounded, color: Colors.white),
                              ],
                            ),
                          ),
                          onDismissed: (direction) {
                             // Only endToStart is enabled
                             _downloadFile(item);
                             // We don't want to remove it from list, so we refresh or just setState to "undo" visual removal?
                             // Dismissible removes widget from tree.
                             // We should probably NOT use Dismissible if we want to keep it, OR we reload the list.
                             // mobile_tcp did: setState(() {}); // "Undo" the dismissal
                             // But Dismissible requires the item to be removed from the list passed to it?
                             // Actually, if we just setState, the list is rebuilt.
                             // Let's try standard flutter pattern: remove from list, then re-add if we want to keep it?
                             // Or just use confirmDismiss to return false but trigger action?
                          },
                          confirmDismiss: (direction) async {
                             _downloadFile(item);
                             return false; // Don't dismiss visually permanently
                          },
                          child: card,
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
