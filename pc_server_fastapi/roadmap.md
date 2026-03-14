# roadmap.md

## 1. System Objectives

The objective is to create a robust, secure, and low-latency remote control architecture that supports two distinct environments:

1. **Local Environment**: Maximum performance and bandwidth when both devices share a local network.
2. **Remote Environment**: Secure and reliable access from any external network without requiring router modifications.

## 2. Technical Stack

* **Web Framework**: FastAPI for low-overhead signaling and control endpoints.
* **Streaming Protocol**: WebRTC for real-time video delivery, replacing legacy UDP/JPEG methods.
* **Screen Capture**: dxcam for efficient Desktop Duplication API (DDA) access.
* **Networking**: Cloudflare Tunnels (Ingress) and STUN (ICE candidates).
* **Mobile Client**: Flutter with `flutter_webrtc` for media playback.

## 3. Connectivity Logic

The CLI in `main.py` manages the server state based on the user's environment.

### Local Mode (`main.py local`)

* Binds to `0.0.0.0` on port 8080.
* The mobile app connects via the PC's private IP address.
* Recommended for screen sharing to ensure the highest frame rate.

### Remote Mode (`main.py remote`)

* Operates behind a Cloudflare Tunnel.
* The mobile app connects to a public HTTPS endpoint.
* Utilizes STUN for NAT traversal.

## 4. WebRTC and STUN Security

The system uses STUN (Session Traversal Utilities for NAT) to establish peer-to-peer connections.

* **Discovery**: STUN is only used to discover the public IP/port of the PC and mobile app.
* **No Relay**: Data is sent directly between devices whenever possible, minimizing latency.
* **Security**: STUN does not handle sensitive data. The actual screen stream is fully encrypted via DTLS and SRTP. Access to the stream is only possible after a successful handshake authenticated by the server's secret key.

## 5. Development Roadmap

* **Phase 1**: Implement the `local` and `remote` CLI subparsers in `main.py`.
* **Phase 2**: Integrate public STUN server configurations into the `RTCPeerConnection` in `api/stream.py`.
* **Phase 3**: Update the Flutter `ApiService` to implement an automatic fallback mechanism (Local IP -> Cloudflare URL).
* **Phase 4**: Optimize WebRTC bitrates for remote connections to account for varying upload speeds.