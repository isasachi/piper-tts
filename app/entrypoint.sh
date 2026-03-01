#!/bin/sh
set -eu

mkdir -p "${VOICE_DIR}"

VOICE="${PIPER_VOICE}"

ONNX_PATH="${VOICE_DIR}/${VOICE}.onnx"
JSON_PATH="${VOICE_DIR}/${VOICE}.onnx.json"

if [ ! -f "$ONNX_PATH" ] || [ ! -f "$JSON_PATH" ]; then
  echo "Voice files not found in ${VOICE_DIR}. Downloading: ${VOICE}"

  wget --tries=5 --timeout=30 --waitretry=5 -O "$ONNX_PATH" \
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx"

  wget --tries=5 --timeout=30 --waitretry=5 -O "$JSON_PATH" \
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/ryan/medium/en_US-ryan-medium.onnx.json"
fi

exec uvicorn server:app --host 0.0.0.0 --port "${PORT}"