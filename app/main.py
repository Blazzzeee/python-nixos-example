import uvicorn
from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def root():
    return {"Hello": "World"}

def main():
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000)
