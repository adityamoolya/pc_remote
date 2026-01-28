from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pycaw.pycaw import AudioUtilities,  IAudioEndpointVolume, EDataFlow,  ERole

from comtypes import CLSCTX_ALL, CoInitialize, CoUninitialize
import ctypes

router = APIRouter()

def get_volume_interface():
    """Get the audio endpoint volume interface manually to avoid pycaw wrapper issues."""
    print("DEBUG: Entering get_volume_interface")
    try:
        CoInitialize()
        print("DEBUG: CoInitialize success")
    except Exception as e:
        print(f"DEBUG: CoInitialize failed (might be ok if already init): {e}")

    try:
        enumerator = AudioUtilities.GetDeviceEnumerator()
        # Pass .value because comtypes expects integers, not Enum objects
        device = enumerator.GetDefaultAudioEndpoint(EDataFlow.eRender.value, ERole.eMultimedia.value)
        interface = device.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        return interface.QueryInterface(IAudioEndpointVolume)
    except Exception as e:
        print(f"DEBUG: Inner failure: {e}")
        import traceback
        traceback.print_exc()
        raise

@router.get("/volume")
def get_volume():
    try:
        volume = get_volume_interface()
        current_percent = int(volume.GetMasterVolumeLevelScalar() * 100)
        return {"level": current_percent}
    except Exception as e:
        print(f"Volume Error: {e}")
        return {"level": 0}
    finally:
        CoUninitialize()

@router.post("/volume/{level}")
def set_volume(level: int):
    try:
        volume = get_volume_interface()
        scalar = max(0.0, min(1.0, level / 100.0))
        volume.SetMasterVolumeLevelScalar(scalar, None)
        return {"new_level": level}
    except Exception as e:
        print(f"Volume Set Error: {e}")
        return {"new_level": level}
    finally:
        CoUninitialize()

@router.post("/playpause")
def play_pause():
    """Simulate media play/pause key press using Windows API."""
    VK_MEDIA_PLAY_PAUSE = 0xB3
    KEYEVENTF_EXTENDEDKEY = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    
    ctypes.windll.user32.keybd_event(VK_MEDIA_PLAY_PAUSE, 0, KEYEVENTF_EXTENDEDKEY, 0)
    ctypes.windll.user32.keybd_event(VK_MEDIA_PLAY_PAUSE, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0)
    
    return {"status": "executed"}

@router.post("/mute")
def toggle_mute():
    """Toggle system mute."""
    try:
        volume = get_volume_interface()
        is_muted = volume.GetMute()
        volume.SetMute(not is_muted, None)
        return {"muted": not is_muted}
    finally:
        CoUninitialize()

@router.post("/next")
def next_track():
    """Simulate media next track key press."""
    VK_MEDIA_NEXT_TRACK = 0xB0
    KEYEVENTF_EXTENDEDKEY = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    
    ctypes.windll.user32.keybd_event(VK_MEDIA_NEXT_TRACK, 0, KEYEVENTF_EXTENDEDKEY, 0)
    ctypes.windll.user32.keybd_event(VK_MEDIA_NEXT_TRACK, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0)
    
    return {"status": "executed"}

@router.post("/prev")
def prev_track():
    """Simulate media previous track key press."""
    VK_MEDIA_PREV_TRACK = 0xB1
    KEYEVENTF_EXTENDEDKEY = 0x0001
    KEYEVENTF_KEYUP = 0x0002
    
    ctypes.windll.user32.keybd_event(VK_MEDIA_PREV_TRACK, 0, KEYEVENTF_EXTENDEDKEY, 0)
    ctypes.windll.user32.keybd_event(VK_MEDIA_PREV_TRACK, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0)
    
    return {"status": "executed"}

#using websocket to control audio
@router.websocket("/ws/volume")
async def websocket_volume(websocket: WebSocket):
    await websocket.accept()
    
    #initialize COM and the interface ONCE at the start of the connection
    try:
        from comtypes import CoInitialize, CoUninitialize
        CoInitialize()
        volume_interface = get_volume_interface() 
        
        while True:
            #wait for data from mobile app
            data = await websocket.receive_text()
            try:
                level = int(data)
                scalar = max(0.0, min(1.0, level / 100.0))
                
                #reuse the existing interface
                volume_interface.SetMasterVolumeLevelScalar(scalar, None)
            except ValueError:
                continue 
                
    except WebSocketDisconnect:
        print("Volume WebSocket closedd")
    finally:
        #clean up COM when the connection is actually finished
        CoUninitialize()