import os
import subprocess
import tempfile
from fastapi import FastAPI, HTTPException
from fastapi.responses import FileResponse
from pydantic import BaseModel

app = FastAPI()

PIPER_BIN = os.getenv("PIPER_BIN", "/usr/local/bin/piper")
PIPER_MODEL = os.getenv("PIPER_MODEL", "/voices/en_US-ryan-medium.onnx")

class TTSRequest(BaseModel):
    text: str

def run(cmd: list[str]):
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or "command failed")

@app.post("/tts/ogg")
def tts_ogg(payload: TTSRequest):
    text = (payload.text or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text is required")

    # temp files
    with tempfile.TemporaryDirectory() as d:
        wav_path = os.path.join(d, "out.wav")
        ogg_path = os.path.join(d, "out.ogg")

        # 1) Piper -> WAV
        # Piper expects text on stdin, output wav path
        try:
            p = subprocess.run(
                [PIPER_BIN, "--model", PIPER_MODEL, "--output_file", wav_path],
                input=text,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            if p.returncode != 0:
                raise RuntimeError(p.stderr.strip() or "piper failed")
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Piper error: {e}")

        # 2) WAV -> OGG/Opus (Telegram-friendly)
        try:
            run([
                "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
                "-i", wav_path,
                "-c:a", "libopus",
                "-b:a", "48k",
                "-vbr", "on",
                "-compression_level", "10",
                ogg_path
            ])
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"ffmpeg error: {e}")

        # 3) Return as audio/ogg
        return FileResponse(
            ogg_path,
            media_type="audio/ogg",
            filename="jarvis.ogg"
        )