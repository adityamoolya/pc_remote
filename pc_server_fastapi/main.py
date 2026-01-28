from fastapi import FastAPI ,Depends
import uvicorn
from api import system, files ,media
from utils.auth_utils import validate_api_key
from utils.discovery import start_mdns_broadcast, stop_mdns_broadcast
from contextlib import asynccontextmanager


@asynccontextmanager
async def lifespan(app: FastAPI):
    # STARTUP: Start broadcasting so the Flutter app can find us
    zc, info = start_mdns_broadcast(port=8080)
    yield   #does all the funcationality while being paused here?
    # SHUTDOWN: Tell the network we are leaving
    stop_mdns_broadcast(zc, info)


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


@app.get("/", tags=["health"])
def root():
    return{"message":"api is healthy"}



if __name__=="__main__":
    # from utils.auth_utils import SECRET_KEY
    # print(f"PAIRING CODE: {SECRET_KEY}")
    uvicorn.run(app, host="0.0.0.0", port=8080)