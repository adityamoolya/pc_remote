# PC Remote

A cross-platform application built with Flutter and Python to remotely control and browse your PC from your mobile device over a local network.

![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi)

---

## Introduction

PC Remote allows you to securely connect your Flutter-based mobile app to a Python server running on your PC. Once connected, you can:

- Browse your computer's file system
- Download files directly to your device
- Execute remote commands like locking your workstation
- Control media playback and system volume
- Manage power options (sleep, shutdown)
- Stream your screen to your phone in real-time via WebRTC

This project started as a learning exercise for TCP sockets and Flutter, with an initial working prototype using raw TCP. For practical purposes, the server has been migrated to FastAPI.

---

## Project Status

**Current State:** Work in Progress

The project contains two implementations:

### FastAPI Version (Active Development)
- `pc_server_fastapi/` - Python FastAPI server
- `mobile_fastapi/` - Flutter mobile app (planned rebuild)

### Legacy TCP Version (Learning Archive)
- `pc_server_tcp/` - Raw TCP socket server
- `mobile_tcp/` - Flutter app using raw TCP

The mobile app is being rebuilt from scratch to work with the new FastAPI backend.

---

## Features

### Implemented (FastAPI Server)
- **API Key Authentication** - Secure access using header-based API key
- **mDNS Service Discovery** - Automatic server discovery using Zeroconf
- **File System Browsing** - List drives and browse directories
- **File Download** - Download files from PC to mobile
- **System Controls** - Lock, Sleep, Shutdown, Task Manager
- **Volume Control** - Get/set volume, mute toggle (REST + WebSocket)
- **Media Playback** - Play/pause, next track, previous track
- **Screen Sharing** - Real-time screen streaming via WebRTC using GPU-accelerated capture (dxcam)

### Planned
- Two-way file transfer
- Clipboard sharing

---

## Tech Stack

### Server (Python 3.12 / FastAPI)
- `fastapi` - Modern async web framework
- `uvicorn` - ASGI server
- `zeroconf` - mDNS service discovery
- `pycaw` - Windows audio control
- `ctypes` - Windows API access
- `aiortc` / `av` - WebRTC peer connection and media
- `dxcam` - GPU-accelerated screen capture (DXGI)

### Mobile App (Flutter/Dart)
- `provider` - State management
- `dio` / `http` - HTTP client
- `bonsoir` - mDNS service discovery
- `flutter_secure_storage` - Secure credential storage
- `path_provider` / `permission_handler` - File operations

---

## Project Structure

```
pc_remote/
├── pc_server_fastapi/       # FastAPI server (active)
│   ├── main.py              # Application entry point
│   ├── requirements.txt
│   ├── api/
│   │   ├── system.py        # Lock, sleep, shutdown endpoints
│   │   ├── files.py         # File browsing and download
│   │   ├── media.py         # Volume & media playback control
│   │   └── stream.py        # WebRTC screen sharing
│   └── utils/
│       ├── auth_utils.py    # API key validation
│       ├── discovery.py     # mDNS broadcast
│       ├── secret_key_gen.py
│       └── webrtc_streamer.py  # dxcam screen capture track
│
├── mobile_fastapi/          # Flutter app (rebuilding)
│   └── lib/
│       └── screens/
│           ├── home_screen.dart
│           ├── control.dart
│           ├── file_explorer.dart
│           └── settings.dart
│
├── pc_server_tcp/           # Legacy TCP server
│   ├── server.py
│   ├── requirements.txt
│   ├── commands.py
│   └── file_utils.py
│
└── mobile_tcp/              # Legacy TCP mobile app
```

---

## API Endpoints

The FastAPI server exposes the following endpoints:

### Health Check
- `GET /` - API health status

### System Controls (`/system`)
- `POST /system/lock` - Lock workstation
- `POST /system/sleep` - Put PC to sleep
- `POST /system/shutdown` - Shutdown PC
- `POST /system/taskmanager` - Open Task Manager

### File Operations (`/files`)
- `GET /files/drives` - List available drives
- `GET /files/list?path=<path>` - List directory contents
- `GET /files/download?path=<path>` - Download a file

### Media Controls (`/media`)
- `GET /media/volume` - Get current volume level
- `POST /media/volume/{level}` - Set volume level (0-100)
- `POST /media/playpause` - Toggle play/pause
- `POST /media/mute` - Toggle system mute
- `POST /media/next` - Next track
- `POST /media/prev` - Previous track
- `WS /media/ws/volume` - Real-time volume control via WebSocket

### Screen Sharing (`/stream`)
- `POST /stream/offer` - WebRTC SDP handshake (send offer, receive answer)

All endpoints except `/` require the `PLEASE_LET_ME_IN` header with a valid API key.

---

## Getting Started

### Prerequisites
- Python 3.12+
- Flutter 3.9.2+
- Windows PC (for system control features)
- Android device on the same Wi-Fi network

### Server Setup

```bash
# 1. Clone and enter the project
git clone <repo-url>
cd PYREMOTE

# 2. Create and activate a virtual environment
python -m venv venv312
venv312\Scripts\activate        # Windows

# 3. Install dependencies
pip install -r pc_server_fastapi/requirements.txt

# 4. Start the server
cd pc_server_fastapi
python main.py
```

The server starts on port **8080** and broadcasts itself via mDNS. A secret API key is auto-generated on first run and stored in `pc_server_fastapi/.env`.

### Mobile App

```bash
# 1. Enter the mobile project
cd mobile_fastapi

# 2. Get dependencies
flutter pub get

# 3. Build and install on your phone (USB debugging must be enabled)
flutter build apk --release
flutter install
```

Make sure your phone and PC are on the **same Wi-Fi network**. The app will auto-discover the server via mDNS.

---

## Authentication

The server uses a simple API key mechanism:

1. A secret key is generated on first run and stored in `.env`
2. The mobile app must send this key in the `PLEASE_LET_ME_IN` header
3. All protected endpoints validate this header before processing requests

---

## Notes

- The FastAPI server includes automatic mDNS broadcasting using Zeroconf
- Service discovery allows the mobile app to find the server without manual IP entry
- The server is Windows-specific for system control features (lock, sleep, volume)
- File operations work cross-platform