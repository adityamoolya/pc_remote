import asyncio
import dxcam
from aiortc import VideoStreamTrack
from av import VideoFrame

class ScreenShareTrack(VideoStreamTrack):
    def __init__(self):
        super().__init__()
        self.camera = None
        self._started = False

    def _ensure_camera(self):
        """Lazy-init:create and start the dxcam capture on first use."""
        if not self._started:
            self.camera = dxcam.create()
            self.camera.start(target_fps=30)
            self._started = True
            print("[WebRTC] dxcam camera started")

    async def recv(self):
        self._ensure_camera()

        pts, time_base = await self.next_timestamp()
        
        frame = None
        while frame is None:
            frame = self.camera.get_latest_frame()
            if frame is None:
                await asyncio.sleep(0.01) 
        
        # dxcam returns RGB; aiortc/av accepts rgb24 directly
        new_frame = VideoFrame.from_ndarray(frame, format="rgb24")
        new_frame.pts = pts
        new_frame.time_base = time_base

        return new_frame

    def stop(self):
        if self.camera is not None and self._started:
            try:
                self.camera.stop()
            except Exception:
                pass
            del self.camera
            self.camera = None
            self._started = False
            print("[WebRTC] dxcam camera stopped and released")
        super().stop()