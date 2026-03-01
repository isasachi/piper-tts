#!/bin/sh
set -eu

mkdir -p "${VOICE_DIR}"

# Download voice files into the mounted volume if missing
# (You can swap URLs to whichever voice you choose.)
VOICE="${PIPER_VOICE}"

ONNX_PATH="${VOICE_DIR}/${VOICE}.onnx"
JSON_PATH="${VOICE_DIR}/${VOICE}.onnx.json"

if [ ! -f "$ONNX_PATH" ] || [ ! -f "$JSON_PATH" ]; then
  echo "Voice files not found in ${VOICE_DIR}. Downloading: ${VOICE}"
  # Example source: the piper-voices repo (you will set the exact URLs for your chosen voice)
  # You must replace these with the correct direct download links for your selected voice files:
  wget -O "$ONNX_PATH"  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx"
  wget -O "$JSON_PATH"  "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json"
fi

# Start API
exec uvicorn server:app --host 0.0.0.0 --port "${PORT}"