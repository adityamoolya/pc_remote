import asyncio
import dxcam
import cv2
import socket
#BUG: fix colour grading issue when streamed
class ScreenStreamer:
    def __init__(self, host="0.0.0.0", port=9999):
        self.host = host
        self.port = port
        self.running = False
        self.camera = dxcam.create()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    async def start_streaming(self, target_ip, target_port):
        self.running = True
        #downgraded to 20
        self.camera.start(target_fps=20) 
        
        while self.running:
            frame = self.camera.get_latest_frame()
            if frame is not None:
                try:
                    # 1. RESIZE: Shrink to 480p to ensure it fits in a UDP packet
                    # A 1080p JPEG is usually > 100KB, UDP limit is 64KB.
                    frame_bgr = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)
                    small_frame = cv2.resize(frame, (854, 480)) 
                    
                    # 2. ENCODE: Use low quality (30) for testing
                    _, buffer = cv2.imencode('.jpg', small_frame, [cv2.IMWRITE_JPEG_QUALITY, 30])
                    data = buffer.tobytes()
                    data_size = len(data)

                    # 3. SEND: Only send if it's under the limit
                    if data_size < 65507:
                        self.sock.sendto(data, (target_ip, target_port))
                        # print(f"[STREAM] Sent frame: {data_size} bytes") # Uncomment to spam-check
                    else:
                        print(f"[STREAM] Frame too large: {data_size} bytes. Lower quality further.")
                
                except Exception as e:
                    print(f"[STREAM] Error: {e}")
            
            await asyncio.sleep(0.03) # ~30 FPS

    def stop_streaming(self):
        print("[STREAM] Stopping...")
        self.running = False
        self.camera.stop()