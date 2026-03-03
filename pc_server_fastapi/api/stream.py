'''
WebRTC Screen Sharing Endpoint

Uses aiortc for WebRTC peer connection and dxcam for GPU-accelerated
screen capture via the Windows Desktop Duplication API (DXGI).

The /offer endpoint handles the SDP handshake between the mobile app and PC.
'''
from fastapi import APIRouter, BackgroundTasks, HTTPException
from aiortc import RTCPeerConnection, RTCSessionDescription
from pydantic import BaseModel
from utils.screen_streamer import ScreenStreamer
from utils.webrtc_streamer import ScreenShareTrack

router = APIRouter()
streamer = ScreenStreamer()
pcs = set()

class WebRTCOffer(BaseModel):
    sdp: str
    type: str

# #UDP appraoch that ive given up
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
        offer = RTCSessionDescription(sdp=offer_data.sdp, type=offer_data.type)

        pc = RTCPeerConnection()
        pcs.add(pc)

        # Add the screen capture track
        video_track = ScreenShareTrack()
        pc.addTrack(video_track)

        @pc.on("connectionstatechange")
        async def on_connectionstatechange():
            print(f"[WebRTC] Connection state: {pc.connectionState}")
            if pc.connectionState in ["failed", "closed"]:
                video_track.stop()   # release dxcam camera
                await pc.close()
                pcs.discard(pc)

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