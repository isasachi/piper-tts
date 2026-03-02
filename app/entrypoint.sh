#!/bin/sh
set -eu

: "${VOICE_DIR:=/data/voices}"
: "${PIPER_VOICE:=en_US-ryan-medium}"
: "${PIPER_MODEL:=${VOICE_DIR}/${PIPER_VOICE}.onnx}"
: "${PORT:=8080}"

mkdir -p "${VOICE_DIR}"

ONNX_PATH="${PIPER_MODEL}"
JSON_PATH="${PIPER_MODEL}.json"

# Parse voice like: en_US-ryan-medium
# lang = en_US, name = ryan, quality = medium
LANG="$(printf "%s" "${PIPER_VOICE}" | cut -d'-' -f1)"
NAME="$(printf "%s" "${PIPER_VOICE}" | cut -d'-' -f2)"
QUALITY="$(printf "%s" "${PIPER_VOICE}" | cut -d'-' -f3)"

# Base language folder is the first 2 letters: "en" from "en_US"
BASE_LANG="$(printf "%s" "${LANG}" | cut -d'_' -f1)"

# Build URLs dynamically from the voice name
ONNX_URL="https://huggingface.co/rhasspy/piper-voices/resolve/main/${BASE_LANG}/${LANG}/${NAME}/${QUALITY}/${LANG}-${NAME}-${QUALITY}.onnx"
JSON_URL="${ONNX_URL}.json"

if [ ! -s "${ONNX_PATH}" ] || [ ! -s "${JSON_PATH}" ]; then
  echo "Voice files not found. Downloading ${PIPER_VOICE} -> ${VOICE_DIR}"

  wget --tries=5 --timeout=30 --waitretry=5 -O "${ONNX_PATH}" "${ONNX_URL}"
  wget --tries=5 --timeout=30 --waitretry=5 -O "${JSON_PATH}" "${JSON_URL}"
fi

# sanity check
test -s "${ONNX_PATH}"
test -s "${JSON_PATH}"

exec uvicorn server:app --host 0.0.0.0 --port "${PORT}"