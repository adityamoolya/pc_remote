from fastapi import FastAPI, Depends
import uvicorn
from api import stun_stream, system, files, media, stream
from utils.auth_utils import validate_api_key
from utils.discovery import start_mdns_broadcast, stop_mdns_broadcast
from contextlib import asynccontextmanager
import ctypes


@asynccontextmanager
async def lifespan(app: FastAPI):
    # STARTUP
    zc, info = await start_mdns_broadcast(port=8080)
    try:
        ctypes.oledll.ole32.CoInitializeEx(None, 0x0)
    except:
        pass

    yield

    # SHUTDOWN
    if zc:
        await stop_mdns_broadcast(zc, info)
    try:
        from comtypes import CoUninitialize
        CoUninitialize()
    except:
        pass


def create_app(mdns: bool = False) -> FastAPI:
    app = FastAPI(
        title="PCremote Server",
        version="2.0.0",
        lifespan=lifespan if mdns else None
    )

    app.include_router(system.router,  prefix="/system", tags=["system manager"],  dependencies=[Depends(validate_api_key)])
    app.include_router(files.router,   prefix="/files",  tags=["file explorer"],   dependencies=[Depends(validate_api_key)])
    app.include_router(media.router,   prefix="/media",  tags=["media tools"])

    if mdns:
        app.include_router(stream.router,  prefix="/stream", tags=["stream"],          dependencies=[Depends(validate_api_key)])

    else: app.include_router(stun_stream.router,  prefix="/STUN_stream", tags=["stream"],          dependencies=[Depends(validate_api_key)])
    @app.get("/", tags=["health"])
    def root():
        return {"message": "api is healthy"}

    return app


# Module-level app so uvicorn "server:app" string import works
app = create_app()


if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8080, reload=True)