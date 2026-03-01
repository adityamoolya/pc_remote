import asyncio
import dxcam
import cv2
import socket #fastapi is based on tcp ,therefoe sockets is used to transport via UDP

class ScreenStreamer:
    def __init__(self, host="0.0.0.0", port=9999):
        self.host = host
        self.port = port
        self.running = False
        self.camera = dxcam.create()
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    async def start_streaming(self, target_ip, target_port):
        self.running = True
        #start capture at a 30 FPS  
        self.camera.start(target_fps=30) 
        
        while self.running:
            frame = self.camera.get_latest_frame()
            if frame is not None:
                #convert BGR to RGB if needed and encode to JPEG
                _, buffer = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 50])
                data = buffer.tobytes()

                #UDP Chunking (just sending small frames)
                if len(data) < 65507: 
                    self.sock.sendto(data, (target_ip, target_port))
            
            await asyncio.sleep(0.01) # Yield to event loop

    def stop_streaming(self):
        self.running = False
        self.camera.stop()