'''
WebRTC Screen Sharing Endpoint

Uses aiortc for WebRTC peer connection and dxcam for GPU-accelerated
screen capture via the Windows Desktop Duplication API (DXGI).

The /offer endpoint handles the SDP handshake between the mobile app and PC.
'''
import traceback
from fastapi import APIRouter, BackgroundTasks, HTTPException
from aiortc import RTCPeerConnection, RTCSessionDescription
from pydantic import BaseModel
from utils.screen_streamer import ScreenStreamer
from utils.webrtc_streamer import ScreenShareTrack

router = APIRouter()
streamer = None   # lazy-init: created only when /start (UDP) is used
pcs = set()

class WebRTCOffer(BaseModel):
    sdp: str
    type: str

# #UDP appraoch that ive given up ,commenting for now
# @router.post("/start")
# async def start_stream(target_ip: str, background_tasks: BackgroundTasks):
#     global streamer
#     if streamer is None:
#         streamer = ScreenStreamer()
#     if not streamer.running:
#         #run the streaming loop in the background
#         background_tasks.add_task(streamer.start_streaming, target_ip, 9999)
#         return {"status": "Streaming started", "target": target_ip}
#     return {"status": "Already streaming"}

# @router.post("/stop")
# async def stop_stream():
#     if streamer is not None:
#         streamer.stop_streaming()
#     return {"status": "Streaming stopped"}


#handles the handshake between  app and PC ,NOT related to UDP-JPEG compression streamming
@router.post("/offer")
async def webrtc_offer(offer_data: WebRTCOffer):
    try:
        offer = RTCSessionDescription(sdp=offer_data.sdp, type=offer_data.type)

        pc = RTCPeerConnection()
        pcs.add(pc)

        video_track = ScreenShareTrack()

        # Register event handlers BEFORE negotiation
        @pc.on("connectionstatechange")
        async def on_connectionstatechange():
            print(f"[WebRTC] Connection state: {pc.connectionState}")
            if pc.connectionState in ["failed", "closed"]:
                video_track.stop()   # release dxcam camera
                await pc.close()
                pcs.discard(pc)

        # Log the offer SDP for debugging
        print(f"[DEBUG] Offer SDP:\n{offer_data.sdp}")

        # 1. Let aiortc create transceivers from the offer
        await pc.setRemoteDescription(offer)

        # 2. Add our screen-capture track
        pc.addTrack(video_track)

        # Debug: show transceiver state
        for i, t in enumerate(pc.getTransceivers()):
            print(f"[DEBUG] T{i}: kind={t.kind}, mid={t.mid}, "
                  f"dir={t.direction}, offerDir={t._offerDirection}")

        # 3. Workaround for aiortc bug: setLocalDescription crashes if
        #    any transceiver has _offerDirection=None.  Fall back to
        #    the transceiver's own direction so and_direction() won't fail.
        for t in pc.getTransceivers():
            if t._offerDirection is None:
                t._offerDirection = t.direction

        # 4. Create and apply the answer
        answer = await pc.createAnswer()
        await pc.setLocalDescription(answer)

        return {
            "sdp": pc.localDescription.sdp,
            "type": pc.localDescription.type
        }
    except Exception as e:
        traceback.print_exc()
        print(f"WebRTC Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))