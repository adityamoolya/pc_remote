enum FileItemType { drive, folder, file, up }

class FileItem {
  final String name;
  final String path;
  final FileItemType type;
  final int? size;

  FileItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    FileItemType type;
    switch (json['type']) {
      case 'drive':
        type = FileItemType.drive;
        break;
      case 'folder':
        type = FileItemType.folder;
        break;
      default:
        type = FileItemType.file;
    }
    return FileItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      type: type,
      size: json['size'],
    );
  }
}
