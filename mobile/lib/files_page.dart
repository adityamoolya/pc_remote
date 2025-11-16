import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
// import 'package:gal/gal.dart';
// Import the files we need from our app
import 'connection_service.dart';
import 'file_system_item.dart';


// NEW IMPORTS for downloading
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class FilesPage extends StatefulWidget {
  // No socket needed, we get it from Provider
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  bool _isLoading = false;

  String? _error;
  String _currentPath = "Drives";
  List<FileSystemItem> _items = [];

  // Service and Stream variables
  late ConnectionService _connectionService;
  StreamSubscription<Uint8List>? _messageSubscription;
  bool _initialFetchDone = false;

  final p.Context _windowsPath = p.Context(style: p.Style.windows);

  String? _downloadingItemPath;

  // --- FIX 1: ADD DATA BUFFER ---
  Uint8List _dataBuffer = Uint8List(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the service from Provider
    _connectionService = Provider.of<ConnectionService>(context);
    // Set up the listener
    _setupListener();

    // Check if we just connected and need to fetch
    if (_connectionService.connectionStatus == ConnectionStatus.connected &&
        !_initialFetchDone) {
      print("FILES_PAGE: Connection is good, starting initial drive fetch.");
      _fetchDrives();
      _initialFetchDone = true;
    } else if (_connectionService.connectionStatus != ConnectionStatus.connected) {
      // Clear data if we disconnect
      if (_initialFetchDone) {
        setState(() {
          _initialFetchDone = false;
          _items = [];
          _currentPath = "Drives";
          _dataBuffer = Uint8List(0); // <-- FIX: Clear buffer on disconnect
        });
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  // --- FIX 2: REPLACE THIS ENTIRE FUNCTION ---
  void _setupListener() {
    _messageSubscription?.cancel();
    _messageSubscription = _connectionService.socketStream?.listen(
          (data) {
        // --- ALL THE DEBUG PRINTS ARE HERE ---
        print("FILES_PAGE: LISTENER: Received data! Chunk Length: ${data.length}");

        // Add new data to our buffer
        _dataBuffer = Uint8List.fromList(_dataBuffer + data);

        print("FILES_PAGE: LISTENER: Buffer size is now: ${_dataBuffer.length}");

        // Process all complete messages in the buffer
        while (true) {
          // 1. Check if we have enough data for the length header
          if (_dataBuffer.length < 4) {
            print("FILES_PAGE: LISTENER: Buffer too small for header. Waiting for more data.");
            break; // Exit loop, wait for next data chunk
          }

          // 2. Read the expected payload length
          final length = ByteData.view(_dataBuffer.buffer).getUint32(0);
          print("FILES_PAGE: LISTENER: Expecting payload length: $length");

          // 3. Check if the buffer contains the full message (header + payload)
          final totalMessageLength = length + 4;
          if (_dataBuffer.length < totalMessageLength) {
            print("FILES_PAGE: LISTENER: Partial data received. Buffer: ${_dataBuffer.length}, Need: $totalMessageLength. Waiting.");
            break; // Exit loop, wait for next data chunk
          }

          // 4. We have a full message! Extract the payload.
          print("FILES_PAGE: LISTENER: Full message received. Processing...");
          final payload = _dataBuffer.sublist(4, totalMessageLength);

          // 5. Remove this message from the buffer
          _dataBuffer = _dataBuffer.sublist(totalMessageLength);
          print("FILES_PAGE: LISTENER: Message processed. Remaining buffer: ${_dataBuffer.length}");


          // 6. --- YOUR EXISTING LOGIC ---
          if (_downloadingItemPath != null) {
            print("FILES_PAGE: LISTENER: Received data, saving as file...");
            final filename = p.basename(_downloadingItemPath!);
            _saveFile(payload, filename);
            _downloadingItemPath = null;
            setState(() { _isLoading = false; });
          } else {
            // Expecting text (file list or error)
            try {
              final message = utf8.decode(payload);
              print("FILES_PAGE: LISTENER: Decoded message: $message");

              if (message.startsWith("ERROR:")) {
                print("FILES_PAGE: LISTENER: Received an ERROR from server.");
                setState(() {
                  _error = message;
                  _isLoading = false;
                });
              } else {
                print("FILES_PAGE: LISTENER: Parsing response...");
                _parseResponse(message); // This will set _isLoading = false
              }
            } catch (e) {
              print("FILES_PAGE: LISTENER: FAILED TO DECODE UTF-8: $e");
              setState(() {
                _error = "Received unexpected data from server.";
                _isLoading = false;
              });
            }
          }
          // --- END OF YOUR EXISTING LOGIC ---

        } // End of while loop, check buffer for more messages
      },
      onError: (error) {
        print("FILES_PAGE: LISTENER: Socket Error: $error");
        setState(() {
          _error = "Socket error: $error";
          _isLoading = false;
          _downloadingItemPath = null;
          _dataBuffer = Uint8List(0); // <-- FIX: Clear buffer
        });
      },
      onDone: () {
        print("FILES_PAGE: LISTENER: Socket Done.");
        setState(() {
          _error = "Connection closed.";
          _initialFetchDone = false;
          _downloadingItemPath = null;
          _dataBuffer = Uint8List(0); // <-- FIX: Clear buffer
        });
      },
    );
  }
  // --- END OF REPLACED FUNCTION ---


  void _parseResponse(String response) {
    print("FILES_PAGE: _parseResponse: Parsing...");
    final newItems = <FileSystemItem>[];
    if (_currentPath != "Drives") {
      newItems.add(FileSystemItem(name: "..", path: "", type: ItemType.up));
    }
    try {
      final lines = response.trim().split('\n');
      for (var line in lines) {
        if (line.isEmpty) continue;
        String name;
        String path;
        ItemType type;
        if (_currentPath == "Drives") {
          type = ItemType.drive;
          name = line;
          path = line;
        } else {
          final parts = line.split(':');
          if (parts.length < 2) continue;
          final typeChar = parts[0];
          name = parts.sublist(1).join(':');
          type = typeChar == 'D' ? ItemType.folder : ItemType.file;
          // Use path package for safe joining
          path = _windowsPath.join(_currentPath, name);
        }
        newItems.add(FileSystemItem(name: name, path: path, type: type));
      }
      setState(() {
        _items = newItems;
        _isLoading = false;
        _error = null;
      });
      print("FILES_PAGE: _parseResponse: Success, found ${newItems.length} items.");
    } catch (e) {
      print("FILES_PAGE: _parseResponse: FAILED with error: $e");
      setState(() {
        _error = "Failed to parse server response.";
        _isLoading = false;
      });
    }
  }


  // COMMAND FUNCTION-O-0-0-0-0-0-
  void _sendCommand(String command) {
    if (_connectionService.connectionStatus != ConnectionStatus.connected ||
        _connectionService.socket == null) return;

    print("FILES_PAGE: _sendCommand: Sending command: $command");
    _connectionService.socket!.write('$command\n');
  }

  void _fetchDrives() {
    setState(() {
      _currentPath = "Drives";
      _isLoading = true;
      _error = null;
      _items = []; // Clear old items
    });
    _sendCommand("DRIVES");
  }

  void _fetchDirectory(String path) {
    setState(() {
      _currentPath = path;
      _isLoading = true;
      _error = null;
      _items = []; // Clear old items
    });
    _sendCommand("LIST_FILES $path");
  }

  void _navigateUp() {
    if (_currentPath == "Drives") return;
    // Check if parent is the root (e.g., "C:\")
    if (p.equals(p.dirname(_currentPath), _currentPath)) {
      _fetchDrives();
      return;
    }
    try {
      final parent = p.dirname(_currentPath);
      _fetchDirectory(parent);
    } catch (e) {
      _fetchDrives(); // Fallback
    }
  }

  void _startDownload(FileSystemItem item) {
    if (item.type == ItemType.folder) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Folder downloads are not yet supported."),
        backgroundColor: Colors.amber,
      ));
      return;
    }

    setState(() {
      _isLoading = true;
      _downloadingItemPath = item.path;
      _error = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Downloading ${item.name}..."),
    ));

    _sendCommand("DOWNLOAD_FILE ${item.path}");
  }

  Future<void> _saveFile(Uint8List data, String filename) async {
    // 1. Check permissions
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    // 2. Save file
    if (status.isGranted) {
      Directory? dir = await getDownloadsDirectory();
      if (dir != null) {
        final filePath = p.join(dir.path, filename);
        await File(filePath).writeAsBytes(data);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Saved to Downloads/${filename}"),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not find Downloads directory."),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Storage permission denied."),
        backgroundColor: Colors.red,
      ));
    }
  }

  IconData _getIcon(ItemType type) {
    switch (type) {
      case ItemType.drive: return Icons.storage_rounded;
      case ItemType.folder: return Icons.folder_rounded;
      case ItemType.file: return Icons.description_outlined;
      case ItemType.up: return Icons.arrow_upward_rounded;
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    // We get the *latest* status from the provider
    // Using context.watch will rebuild this widget when the connection status changes
    final status = context.watch<ConnectionService>().connectionStatus;

    if (status != ConnectionStatus.connected) {
      // We are not connected, clear everything
      return const Center(child: Text('Not Connected.'));
    }

    // We are connected, build the UI
    return Column(
      children: [
        // --- (Top "AppBar") ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.black26,
          child: Row(
            children: [
              // if (_currentPath != "Drives")
              //   IconButton(
              //     icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              //     onPressed: _navigateUp,
              //     color: Colors.white,
              //     tooltip: 'Go up a directory',
              //   ),
              Expanded(
                child: Text(
                  _currentPath == "Drives"
                      ? "My Computer"
                      : _currentPath.replaceAll('\\', '/'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        // --- (Main Content) ---
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment:  MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_currentPath == "Drives") {
                  _fetchDrives();
                } else {
                  _fetchDirectory(_currentPath);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(child: Text(_currentPath == "Drives" ? 'No drives found.' : 'This folder is empty.'));
    }

    if (_currentPath == "Drives") {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _items.map((item) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            color: Colors.grey[850],
            child: ListTile(
              leading: Icon(_getIcon(item.type), color: Colors.blueAccent),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
              onTap: () => _fetchDirectory(item.path),
            ),
          )).toList(),
        ),
      );
    }

    // --- Folder/File List with Dismissible ---
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        if (item.type == ItemType.up) {
          return ListTile(
            leading: Icon(_getIcon(item.type)),
            title: Text(item.name),
            onTap: () => _navigateUp(),
          );
        }

        return Dismissible(
          key: Key(item.path),
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
            _startDownload(item);
            setState(() {}); // "Undo" the dismissal
          },
          child: ListTile(
            leading: Icon(_getIcon(item.type)),
            title: Text(item.name),
            trailing: item.type == ItemType.folder
                ? const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey)
                : null,
            onTap: () {
              if (item.type == ItemType.folder) {
                _fetchDirectory(item.path);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on file: ${item.name}')),
                );
              }
            },
          ),
        );
      },
    );
  }
}