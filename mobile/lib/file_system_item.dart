// lib/file_system_item.dart
enum ItemType { drive, folder, file, up } // Added 'up'

class FileSystemItem {
  final String name;
  final String path;
  final ItemType type;

  FileSystemItem({required this.name, required this.path, required this.type});
}
