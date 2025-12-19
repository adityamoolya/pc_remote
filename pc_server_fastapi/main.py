from fastapi import FastAPI 
import uvicorn
from api import system, files ,media


app= FastAPI(   title="PCremote Server",
             version="2.0.0",
 )

app.include_router(system.router, prefix="/system", tags=["system manger"])
app.include_router(files.router, prefix="/files", tags=["file explore"])
app.include_router(media.router, prefix="/files", tags=["media tools"])


@app.get("/", tags=["health"])
def root():
    return{"message":"api is healthy"}



if __name__=="__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)