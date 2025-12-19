from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
import os
import string

router = APIRouter()

@router.get("/drives")
async def get_drives():
    drives = [f"{l}:\\" for l in string.ascii_uppercase if os.path.exists(f"{l}:\\")]
    return {"drives": drives}

@router.get("/list")
async def list_files(path: str = "."):
    try:
        abs_path = os.path.abspath(path)
        items = os.listdir(abs_path)
        return {
            "path": abs_path,
            "items": [{"name": i, "type": "D" if os.path.isdir(os.path.join(abs_path, i)) else "F"} for i in items]
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/download")
async def download(path: str):
    if os.path.exists(path) and os.path.isfile(path):
        return FileResponse(path) 
    raise HTTPException(status_code=404, detail="File not found")