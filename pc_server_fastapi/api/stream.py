'''
1. CAPTURE: Uses 'dxcam' to leverage the Windows Desktop Duplication API (DXGI).
   This is high-performance, grabbing frames directly from the GPU with 
   minimal CPU overhead compared to standard screenshot methods using pillow or similar libs.

2. ENCODE: Each captured frame is encoded into a JPEG format using 'cv2' 
   (OpenCV). Quality is reduced (e.g., 50%) to shrink the payload size for 
   faster network transmission.

3. TRANSPORT: Encoded byte data is streamed over UDP
   Unlike TCP, UDP doesn't wait for acknowledgments, which significantly 
   reduces latency. It's ideal for real-time video where losing a single 
   frame is better than the whole stream lagging to catch up.

4. CONTROL: The FastAPI endpoints (/start, /stop) act as a signaling layer 
   to manage the lifecycle of the background streaming task.
'''

from fastapi import APIRouter, BackgroundTasks
from utils.screen_streamer import ScreenStreamer

router = APIRouter()
streamer = ScreenStreamer()

@router.post("/start")
async def start_stream(target_ip: str, background_tasks: BackgroundTasks):
    if not streamer.running:
        #run the streaming loop in the background
        background_tasks.add_task(streamer.start_streaming, target_ip, 9999)
        return {"status": "Streaming started", "target": target_ip}
    return {"status": "Already streaming"}

@router.post("/stop")
async def stop_stream():
    streamer.stop_streaming()
    return {"status": "Streaming stopped"}