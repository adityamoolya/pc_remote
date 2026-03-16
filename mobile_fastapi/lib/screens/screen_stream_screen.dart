import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/api_service.dart';

class ScreenStreamScreen extends StatefulWidget {
  final ApiService api;
  final bool isBroadcastMode;
  const ScreenStreamScreen({super.key, required this.api, this.isBroadcastMode = false});

  @override
  State<ScreenStreamScreen> createState() => _ScreenStreamScreenState();
}

class _ScreenStreamScreenState extends State<ScreenStreamScreen> {
  RTCPeerConnection? _peerConnection;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  @override
  void dispose() {
    _stopWebRTC();
    super.dispose();
  }

  Future<void> _initWebRTC() async {
    try {
      await _remoteRenderer.initialize();

      // configuration for WebRTC
      Map<String, dynamic> configuration = {
        'iceServers': [
          {'url': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video') {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
          });
        }
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint('WebRTC Connection State: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _setError('Connection failed. Please check if the server is still running.');
        }
      };

      // Add a recvonly video transceiver so the offer includes a video m= section.
      // (The deprecated offerToReceiveVideo constraint no longer works in unified-plan.)
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Create offer
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send to server
      final endpoint = widget.isBroadcastMode ? '/STUN_stream/offer' : '/stream/offer';
      final answerData = await widget.api.sendWebRTCOffer(offer.sdp!, offer.type!, endpointPath: endpoint);
      if (answerData == null) {
        _setError('Failed to connect to streaming server.');
        return;
      }

      // Set remote description
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(answerData['sdp'], answerData['type']),
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      _setError('Error initializing stream: $e');
    }
  }

  void _setError(String msg) {
    if (mounted) {
      setState(() {
        _error = msg;
        _loading = false;
      });
    }
  }

  Future<void> _stopWebRTC() async {
    _remoteRenderer.srcObject = null;
    await _remoteRenderer.dispose();
    await _peerConnection?.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PC Screen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 24),
                        ElevatedButton(onPressed: _initWebRTC, child: const Text('Retry'))
                      ],
                    ),
                  )
                : RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                  ),
      ),
    );
  }
}
