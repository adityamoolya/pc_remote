import asyncio
import dxcam
from aiortc import VideoStreamTrack
from av import VideoFrame

class ScreenShareTrack(VideoStreamTrack):
    def __init__(self):
        super().__init__()
        self.camera = dxcam.create()
        self.camera.start(target_fps=30)

    async def recv(self):
        pts, time_base = await self.next_timestamp()
        
        frame = None
        while frame is None:
            frame = self.camera.get_latest_frame()
            if frame is None:
                # Sleep briefly so we don't peg the CPU while waiting
                await asyncio.sleep(0.01) 
        
        # Once we have a frame, convert it
        # Note: Added the BGR/RGB flip here just in case the blue tint persists
        new_frame = VideoFrame.from_ndarray(frame, format="rgb24")
        new_frame.pts = pts
        new_frame.time_base = time_base

        return new_frame

    def stop(self):
        self.camera.stop()
        super().stop()