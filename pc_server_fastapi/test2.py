"""
test2.py — WebRTC screen share viewer

Connects to the server's /stream/offer endpoint via WebRTC,
receives video frames, and displays them in an OpenCV window.

Usage:
    1. Start server:  python main.py
    2. Run this:      python test2.py
    3. Press 'q' to quit
"""

import asyncio
import threading
import cv2
import numpy as np
import aiohttp
import os
from aiortc import RTCPeerConnection, RTCSessionDescription, MediaStreamTrack
from dotenv import load_dotenv

SERVER_URL = "http://127.0.0.1:8080"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# Always load .env from the same directory as this script (pc_server_fastapi/)
load_dotenv(os.path.join(SCRIPT_DIR, ".env"))

API_KEY = os.getenv("PC_REMOTE_SECRET_KEY", "")
if not API_KEY:
    print("[ERROR] PC_REMOTE_SECRET_KEY not found in .env")
    exit(1)

HEADERS = {"PLEASE_LET_ME_IN": API_KEY}

# Shared frame between async receiver and OpenCV display loop
latest_frame = None
frame_lock = threading.Lock()
running = True


async def receive_frames():
    """Connect via WebRTC and receive frames into the shared variable."""
    global latest_frame, running

    pc = RTCPeerConnection()

    @pc.on("track")
    def on_track(track: MediaStreamTrack):
        print(f"[WebRTC] Received track: kind={track.kind}")

        async def consume():
            global latest_frame, running
            frame_count = 0
            try:
                while running:
                    frame = await asyncio.wait_for(track.recv(), timeout=5.0)
                    frame_count += 1

                    # Convert av.VideoFrame to numpy BGR array for OpenCV
                    img = frame.to_ndarray(format="bgr24")

                    with frame_lock:
                        latest_frame = img

                    if frame_count == 1:
                        print(f"[WebRTC] First frame received! {img.shape[1]}x{img.shape[0]}")

            except asyncio.TimeoutError:
                print(f"[WebRTC] Timeout — received {frame_count} frames total")
            except Exception as e:
                if running:
                    print(f"[WebRTC] Error: {e}")
            finally:
                running = False

        asyncio.ensure_future(consume())

    @pc.on("connectionstatechange")
    async def on_state():
        print(f"[WebRTC] Connection: {pc.connectionState}")
        if pc.connectionState == "failed":
            global running
            running = False

    # recvonly — we only want to receive video
    pc.addTransceiver("video", direction="recvonly")

    offer = await pc.createOffer()
    await pc.setLocalDescription(offer)
    print("[WebRTC] Sending offer to server...")

    # Send SDP offer to server
    async with aiohttp.ClientSession() as session:
        try:
            async with session.post(
                f"{SERVER_URL}/stream/offer",
                json={"sdp": pc.localDescription.sdp, "type": pc.localDescription.type},
                headers=HEADERS,
                timeout=aiohttp.ClientTimeout(total=10),
            ) as resp:
                if resp.status != 200:
                    text = await resp.text()
                    print(f"[ERROR] Server returned {resp.status}: {text}")
                    running = False
                    return
                answer_data = await resp.json()
                print("[WebRTC] Received answer from server")
        except Exception as e:
            print(f"[ERROR] Could not connect: {e}")
            print("        Make sure the server is running (python main.py)")
            running = False
            return

    answer = RTCSessionDescription(sdp=answer_data["sdp"], type=answer_data["type"])
    await pc.setRemoteDescription(answer)
    print("[WebRTC] Handshake complete — waiting for frames...")

    # Keep alive until display loop stops
    while running:
        await asyncio.sleep(0.1)

    await pc.close()
    print("[WebRTC] Connection closed")


def start_async_loop():
    """Run the asyncio event loop in a background thread."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    loop.run_until_complete(receive_frames())


if __name__ == "__main__":
    print("--- WebRTC Stream Viewer ---")
    print("Press 'q' to quit")
    print()

    # Start WebRTC receiver in a background thread
    thread = threading.Thread(target=start_async_loop, daemon=True)
    thread.start()

    # OpenCV display loop on main thread (same pattern as test.py)
    try:
        while running:
            with frame_lock:
                frame = latest_frame

            if frame is not None:
                cv2.imshow("WebRTC Stream", frame)

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        running = False
        thread.join(timeout=5)
        cv2.destroyAllWindows()
        print("Done.")
