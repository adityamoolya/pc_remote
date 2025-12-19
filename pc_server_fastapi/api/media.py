from fastapi import APIRouter
from pycaw.pycaw import AudioUtilities  #type: ignore
# import subprocess

router = APIRouter()

def get_volume_interface():
    speakers = AudioUtilities.GetSpeakers()
    return speakers.EndpointVolume

@router.get("/volume")
async def get_volume():
    volume = get_volume_interface()
    current_percent = int(volume.GetMasterVolumeLevelScalar() * 100)
    return {"level": current_percent}

@router.post("/volume/{level}")
async def set_volume(level: int):
    volume = get_volume_interface()
    scalar = max(0.0, min(1.0, level / 100.0))
    volume.SetMasterVolumeLevelScalar(scalar, None)
    return {"new_level": level}

@router.post("/playpause")
async def play_pause():
    #todo
    return {"status": "executed"}