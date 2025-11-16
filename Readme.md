# PC Remote

A cross-platform application built with Flutter and Python to remotely control and browse your PC from your mobile device over a local network.

![Python](https://img.shields.io/badge/Python-3.12-blue?logo=python)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2+-02569B?logo=flutter)

---

## 📱 Introduction

PC Remote allows you to securely connect your Flutter-based mobile app to a Python server running on your PC. Once connected, you can:

- 🗂️ Browse your computer's file system
- 📥 Download files directly to your device
- 🔒 Execute remote commands like locking your workstation
- 🎵 Control media playback and system volume
- 🔋 Manage power options (sleep, shutdown, restart)

The connection is established securely over your local Wi-Fi by scanning a QR code that contains your PC's IP address and a one-time secret key generated at server startup.

---

## ✨ Features

### Current Features
- **🔐 Secure QR Code Connection** - Easily connect by scanning a QR code from the server terminal
- **📂 File System Browsing** - Browse PC drives (C:, D:, etc.) and navigate folders
- **📥 File Download** - Download files to your phone by swiping left on any file
  - Files are saved to `android/data/com.pc_remote_project.pc_remote` on Android
- **🔒 Remote Lock** - Lock your PC remotely
- **🎵 Media Controls** - Play/Pause, Next, Previous track
- **🔊 Volume Control** - Live volume adjustment with mute toggle
- **⚡ Power Management** - Sleep, Shutdown, and Restart commands
- **🖥️ System Access** - Quick access to Task Manager and Settings

---

## 💻 Tech Stack

### Server (Python 3.12)
- `socket` - Core TCP networking
- `threading` - Multi-client support
- `qrcode` - Terminal QR code generation
- `pycaw` - Audio control
- `comtypes` - Windows COM interface

### Mobile App (Flutter/Dart)
- `provider` - State management
- `mobile_scanner` - QR code scanning
- `path_provider` & `permission_handler` - File operations
- `path` - Cross-platform path handling

---

## 🚀 Installation

### Prerequisites
- **Python 3.12** installed on your PC
- **Android device** and **PC on the same Wi-Fi network**
- Ability to install APKs on your Android device

### 1️⃣ Server Setup (PC)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/adityamoolya/pc_remote.git
   cd pc_remote
   ```

2. **Install Python dependencies:**
   ```bash
   cd v2-PC-client
   pip install -r requiremnets.txt
   ```

3. **Run the server:**
   ```bash
   python server.py
   ```

4. A large **QR code** will appear in your terminal. Keep this window open.

### 2️⃣ Client Setup (Mobile)

1. **Find the APK:**
   - Navigate to the `APK` folder in the cloned repository

2. **Install the App:**
   - Copy the appropriate APK for your device architecture:
     - `app-arm64-v8a-release.apk` (most modern Android phones)
     - `app-armeabi-v7a-release.apk` (older 32-bit devices)
     - `app-x86_64-release.apk` (x86 devices/emulators)
   
3. Transfer to your phone and install (you may need to enable "Install from unknown sources")

### 3️⃣ Connect

1. Open the app and tap **"Connect"**
2. Grant camera permissions
3. Scan the QR code from your PC terminal
4. The status indicator will turn **green** when connected
5. Tap the **"Files"** tab to start browsing

---

## 📖 Usage

### File Management
- **Browse:** Tap folders to navigate
- **Download:** Swipe left on any file to download it to your phone
- **Go Back:** Tap the ".." item at the top of folders

### Remote Control
- **Home Tab:** Access all control features organized by category
- **Power:** Lock, Sleep, Shutdown, Restart
- **Media:** Play/Pause, Next, Previous track
- **Volume:** Live volume slider with mute button
- **System:** Quick access to Task Manager and Settings

### Disconnecting
- Tap the **"Disconnect"** button in the top-right corner
- The server will continue running for other connections

---

## 🎯 Future Goals

This project is actively being developed. Planned features include:

- 🖥️ **Remote Desktop** - Real-time screen streaming
- 🖱️ **Remote Input** - Control mouse and keyboard from mobile
- 📤 **Two-Way File Transfer** - Upload files from mobile to PC
- 📋 **Clipboard Sharing** - Sync clipboard between devices
- 💻 **Remote Terminal** - Execute shell commands from the app
- 📺 **Display Management** - Multi-monitor control
- 🔔 **Notifications** - PC notifications mirrored to mobile

---

## 🔧 Development

### Building from Source

**Mobile App:**
```bash
cd mobile
flutter pub get
flutter build apk --split-per-abi
```

**Server:**
```bash
cd v2-PC-client
pip install -r requiremnets.txt
python server.py
```

### Project Structure
```
pc_remote/
├── mobile/              # Flutter mobile application
│   ├── lib/            # Dart source files
│   └── android/        # Android specific files
├── v2-PC-client/       # Python server
│   ├── server.py       # Main server file
│   ├── commands.py     # Command handlers
│   ├── file_utils.py   # File system utilities
│   └── network_utils.py # Network helpers
└── APK/                # Pre-built Android packages
```

---



## 🐛 Known Issues

- Folder downloads are not yet supported (individual file downloads only)
- Server requires manual restart if it crashes
- Volume control requires Windows OS with audio devices

---

## 💡 Tips

- Keep the server terminal window open while using the app
- Ensure both devices remain on the same Wi-Fi network
- The secret key changes each time the server restarts for security
- Downloaded files can be found in your Android file manager under the app's data folder

---