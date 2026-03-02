import os
import subprocess
import tempfile
from typing import Optional

from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel
from starlette.background import BackgroundTask

app = FastAPI()

PIPER_BIN = os.getenv("PIPER_BIN", "piper")
PIPER_MODEL = os.getenv("PIPER_MODEL")  # your Dockerfile sets this

def _cleanup_files(*paths: str) -> None:
    for p in paths:
        try:
            os.remove(p)
        except FileNotFoundError:
            pass

class TTSRequest(BaseModel):
    text: Optional[str] = None

@app.post("/tts/ogg")
def tts_ogg(payload: TTSRequest):
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")

    if not PIPER_MODEL:
        raise HTTPException(status_code=500, detail="PIPER_MODEL env var is not set")

    # Create temp files that survive past the request handler
    wav_fd, wav_path = tempfile.mkstemp(suffix=".wav")
    ogg_fd, ogg_path = tempfile.mkstemp(suffix=".ogg")
    os.close(wav_fd)
    os.close(ogg_fd)

    # 1) Piper -> WAV
    try:
        p = subprocess.run(
            [PIPER_BIN, "--model", PIPER_MODEL, "--output_file", wav_path],
            input=text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if p.returncode != 0:
            raise RuntimeError((p.stderr or "").strip() or "piper failed")
    except Exception as e:
        _cleanup_files(wav_path, ogg_path)
        raise HTTPException(status_code=500, detail=f"Piper error: {e}")

    # 2) WAV -> OGG/Opus
    try:
        p2 = subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-hide_banner",
                "-loglevel",
                "error",
                "-i",
                wav_path,
                "-c:a",
                "libopus",
                "-b:a",
                "48k",
                "-vbr",
                "on",
                "-compression_level",
                "10",
                ogg_path,
            ],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if p2.returncode != 0:
            err = (p2.stderr or b"").decode("utf-8", "ignore").strip()
            raise RuntimeError(err or "ffmpeg failed")
    except Exception as e:
        _cleanup_files(wav_path, ogg_path)
        raise HTTPException(status_code=500, detail=f"ffmpeg error: {e}")

    # 3) Return file, then delete it AFTER response is sent
    return FileResponse(
        path=ogg_path,
        media_type="audio/ogg",
        filename="jarvis.ogg",
        background=BackgroundTask(_cleanup_files, wav_path, ogg_path),
    )