from fastapi import APIRouter, HTTPException
from aiortc import RTCPeerConnection, RTCSessionDescription, RTCConfiguration, RTCIceServer
from pydantic import BaseModel
from utils.webrtc_streamer import ScreenShareTrack
import traceback

router = APIRouter()
pcs = set()

ICE_CONFIG = RTCConfiguration(iceServers=[
    RTCIceServer(urls="stun:stun.l.google.com:19302"),
    RTCIceServer(urls="stun:stun1.l.google.com:19302"),
])

class WebRTCOffer(BaseModel):
    sdp: str
    type: str

@router.post("/offer")
async def webrtc_offer(offer_data: WebRTCOffer):
    try:
        offer = RTCSessionDescription(sdp=offer_data.sdp, type=offer_data.type)
        pc = RTCPeerConnection(configuration=ICE_CONFIG)  # only difference from stream.py
        pcs.add(pc)

        video_track = ScreenShareTrack()

        @pc.on("connectionstatechange")
        async def on_connectionstatechange():
            print(f"[WebRTC STUN] Connection state: {pc.connectionState}")
            if pc.connectionState in ["failed", "closed"]:
                video_track.stop()
                await pc.close()
                pcs.discard(pc)

        await pc.setRemoteDescription(offer)
        pc.addTrack(video_track)

        for t in pc.getTransceivers():
            if t._offerDirection is None:
                t._offerDirection = t.direction

        answer = await pc.createAnswer()
        await pc.setLocalDescription(answer)

        return {
            "sdp": pc.localDescription.sdp,
            "type": pc.localDescription.type
        }
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))