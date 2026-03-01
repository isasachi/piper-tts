import os
import subprocess
import tempfile
from fastapi import FastAPI
from pydantic import BaseModel
from fastapi.responses import FileResponse

PIPER_BIN = os.getenv("PIPER_BIN", "/usr/local/bin/piper")
MODEL_PATH = os.getenv("PIPER_MODEL", "/voices/en_US-lessac-medium.onnx")

app = FastAPI()

class TTSRequest(BaseModel):
    text: str

@app.post("/tts")
def tts(req: TTSRequest):
    text = (req.text or "").strip()
    if not text:
        return {"error": "text is required"}

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as out_f:
        out_path = out_f.name

    # Piper reads text from stdin
    p = subprocess.run(
        [PIPER_BIN, "--model", MODEL_PATH, "--output_file", out_path],
        input=text.encode("utf-8"),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if p.returncode != 0:
        return {"error": "piper failed", "details": p.stderr.decode("utf-8", errors="ignore")}

    return FileResponse(out_path, media_type="audio/wav", filename="speech.wav")
