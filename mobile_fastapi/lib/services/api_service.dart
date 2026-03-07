
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/file_item.dart';

class ApiService {
  late final Dio _dio;
  String _baseUrl = '';


  // Cache
  List<FileItem>? _cachedDrives;
  final Map<String, _CacheEntry<List<FileItem>>> _dirCache = {};
  int? _cachedVolume;
  static const _cacheDuration = Duration(seconds: 30);

  String get baseUrl => _baseUrl;

  void configure({required String baseUrl, required String apiKey}) {
    _baseUrl = baseUrl;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'PLEASE_LET_ME_IN': apiKey},
    ));
    // Clear cache on reconfigure
    _cachedDrives = null;
    _dirCache.clear();
    _cachedVolume = null;
  }

  // ─── Health ───
  Future<bool> healthCheck() async {
    try {
      final resp = await _dio.get('/');
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── System Controls ───
  Future<bool> systemAction(String action) async {
    try {
      await _dio.post('/system/$action');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Media Controls ───
  Future<bool> mediaAction(String action) async {
    try {
      await _dio.post('/media/$action');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Volume ───
  Future<int?> getVolume({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedVolume != null) return _cachedVolume;
    try {
      final resp = await _dio.get('/media/volume');
      _cachedVolume = resp.data['level'] as int;
      return _cachedVolume;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setVolume(int level) async {
    try {
      await _dio.post('/media/volume/$level');
      _cachedVolume = level;
      return true;
    } catch (_) {
      return false;
    }
  }

  void updateVolumeCache(int level) {
    _cachedVolume = level;
  }

  // ─── Files ───
  Future<List<FileItem>?> getDrives({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedDrives != null) return _cachedDrives;
    try {
      final resp = await _dio.get('/files/drives');
      final List<dynamic> data = resp.data;
      _cachedDrives = data.map((d) => FileItem.fromJson(d as Map<String, dynamic>)).toList();
      return _cachedDrives;
    } catch (_) {
      return null;
    }
  }

  Future<List<FileItem>?> listFiles(String path, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _dirCache[path];
      if (cached != null && !cached.isExpired) return cached.data;
    }
    try {
      final resp = await _dio.get('/files/list', queryParameters: {'path': path});
      final List<dynamic> data = resp.data;
      final items = data.map((d) => FileItem.fromJson(d as Map<String, dynamic>)).toList();
      _dirCache[path] = _CacheEntry(items);
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> downloadFile(String path) async {
    try {
      final resp = await _dio.get(
        '/files/download',
        queryParameters: {'path': path},
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(resp.data);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> sendWebRTCOffer(String sdp, String type) async {
    try {
      final resp = await _dio.post(
        '/stream/offer',
        data: {'sdp': sdp, 'type': type},
      );
      return resp.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String get wsVolumeUrl {
    final uri = Uri.parse(_baseUrl);
    return 'ws://${uri.host}:${uri.port}/media/ws/volume';
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > ApiService._cacheDuration;
}
