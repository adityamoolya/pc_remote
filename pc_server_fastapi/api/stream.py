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
import json
from fastapi import APIRouter, BackgroundTasks ,Request ,HTTPException
from utils.screen_streamer import ScreenStreamer
from aiortc import RTCPeerConnection, RTCSessionDescription
from pydantic import BaseModel
from utils.webrtc_streamer import ScreenShareTrack

router = APIRouter()
streamer = ScreenStreamer()
pcs = set()

class WebRTCOffer(BaseModel):
    sdp: str
    type: str

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


#handles the handshake between  app and PC ,NOT related to UDP-JPEG compression streamming
@router.post("/offer")
async def webrtc_offer(offer_data: WebRTCOffer):
    try:
        # already validated that offer_data contains sdp and type
        offer = RTCSessionDescription(sdp=offer_data.sdp, type=offer_data.type)

        pc = RTCPeerConnection()
        pcs.add(pc)

        @pc.on("connectionstatechange")
        async def on_connectionstatechange():
            if pc.connectionState in ["failed", "closed"]:
                await pc.close()
                pcs.discard(pc)

        # Add the screen capture track
        video_track = ScreenShareTrack()
        pc.addTrack(video_track)

        # Set remote description and create answer
        await pc.setRemoteDescription(offer)
        answer = await pc.createAnswer()
        await pc.setLocalDescription(answer)

        return {
            "sdp": pc.localDescription.sdp,
            "type": pc.localDescription.type
        }
    except Exception as e:
        print(f"WebRTC Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))