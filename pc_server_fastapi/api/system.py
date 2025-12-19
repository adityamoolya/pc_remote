from fastapi import APIRouter
import ctypes
import os
import subprocess

router = APIRouter()

@router.post("/lock")
async def lock_pc():
    ctypes.windll.user32.LockWorkStation()
    return {"message": "executed"}

@router.post("/sleep")
async def sleep_pc():
    subprocess.run("rundll32.exe powrprof.dll,SetSuspendState 0,1,0", shell=True)
    return {"message": "executed"}

@router.post("/shutdown")
async def shutdown():
    os.system("shutdown /s /t 0")
    return {"message": "executed"}

@router.post("/taskmanager")
async def task_mgr():
    subprocess.Popen("taskmgr.exe", shell=True)
    return {"message": "executed"}