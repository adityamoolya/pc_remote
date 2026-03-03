from fastapi import FastAPI ,Depends
import uvicorn
from api import system, files ,media , stream
from utils.auth_utils import validate_api_key
from utils.discovery import start_mdns_broadcast, stop_mdns_broadcast
from contextlib import asynccontextmanager
import ctypes

@asynccontextmanager
async def lifespan(app: FastAPI):
    # STARTUP
    zc, info = await start_mdns_broadcast(port=8080)
    # Initialize COM for the main thread
    try:
        ctypes.oledll.ole32.CoInitializeEx(None, 0x0)
    except: pass
    
    yield
    
    # SHUTDOWN
    if zc:
        await stop_mdns_broadcast(zc, info)
    
    from comtypes import CoUninitialize
    try:
        CoUninitialize()
    except: pass

app= FastAPI(
    title="PCremote Server",
    version="2.0.0",
    lifespan=lifespan  #this enables mDNS broadcast on startup and stops it on shutdown
)

app.include_router(
    system.router, 
    prefix="/system", 
    tags=["system manager"],
    dependencies=[Depends(validate_api_key)]
)

app.include_router(
    files.router, 
    prefix="/files", 
    tags=["file explorer"],
    dependencies=[Depends(validate_api_key)]
)

app.include_router(
    media.router, 
    prefix="/media" , 
    tags=["media tools"],
    # dependencies=[Depends(validate_api_key)]
    #turned off temperaily for debugging
)

app.include_router(
    stream.router, 
    prefix="/stream", 
    tags=["stream"], 
    dependencies=[Depends(validate_api_key)]
)


@app.get("/", tags=["health"])
def root():
    return{"message":"api is healthy"}



if __name__=="__main__":
    # from utils.auth_utils import SECRET_KEY
    # print(f"PAIRING CODE: {SECRET_KEY}")
    uvicorn.run("server:app", host="0.0.0.0", port=8080,reload=True)