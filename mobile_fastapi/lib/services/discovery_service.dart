import 'dart:async';
import 'package:bonsoir/bonsoir.dart';

class DiscoveryService {
  static const String serviceType = '_pcremote._tcp';
  
  BonsoirDiscovery? _discovery;
  StreamSubscription? _subscription;
  
  /// Discovers the PC Remote server on the local network.
  /// Returns a map with 'ip' and 'port' if found, null otherwise.
  Future<Map<String, dynamic>?> discoverServer({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final completer = Completer<Map<String, dynamic>?>();
    
    try {
      _discovery = BonsoirDiscovery(type: serviceType);
      await _discovery!.initialize();
      
      _subscription = _discovery!.eventStream!.listen((event) {
        switch (event) {
          case BonsoirDiscoveryServiceFoundEvent():
            // When service is found, resolve it to get IP address
            event.service.resolve(_discovery!.serviceResolver);
            break;
          case BonsoirDiscoveryServiceResolvedEvent():
            // Service resolved - we now have IP and port
            final service = event.service;
            final ip = service.host;
            final port = service.port;
            final pcName = service.attributes['pc_name'] ?? 'Unknown PC';
            
            if (!completer.isCompleted) {
              completer.complete({
                'ip': ip,
                'port': port,
                'pcName': pcName,
              });
            }
            break;
          default:
            break;
        }
      });
      
      await _discovery!.start();
      
      // Timeout handling
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      return await completer.future;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return null;
    } finally {
      await stopDiscovery();
    }
  }
  
  Future<void> stopDiscovery() async {
    await _subscription?.cancel();
    await _discovery?.stop();
    _subscription = null;
    _discovery = null;
  }
}
