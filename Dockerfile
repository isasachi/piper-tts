FROM python:3.11-slim

# --- OS deps ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates tar ffmpeg \
    libstdc++6 libgomp1 \
  && rm -rf /var/lib/apt/lists/*

ARG PIPER_TAG=2023.11.14-2
ARG TARGETARCH

RUN set -eux; \
  case "${TARGETARCH:-amd64}" in \
    amd64) PIPER_ARCH="x86_64" ;; \
    arm64) PIPER_ARCH="aarch64" ;; \
    *) echo "Unsupported TARGETARCH=${TARGETARCH}"; exit 1 ;; \
  esac; \
  mkdir -p /opt/piper; \
  wget -O /tmp/piper.tar.gz "https://github.com/rhasspy/piper/releases/download/${PIPER_TAG}/piper_linux_${PIPER_ARCH}.tar.gz"; \
  tar -xzf /tmp/piper.tar.gz -C /opt/piper; \
  rm -f /tmp/piper.tar.gz; \
  PIPER_BIN="$(find /opt/piper -maxdepth 4 -type f -name piper | head -n 1)"; \
  test -n "$PIPER_BIN"; \
  chmod 0755 "$PIPER_BIN"; \
  ln -sf "$PIPER_BIN" /usr/local/bin/piper

WORKDIR /app
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app/server.py /app/server.py
COPY app/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Where Railway Volume will be mounted
ENV VOICE_DIR=/data/voices
ENV PIPER_BIN=/usr/local/bin/piper

ENV PIPER_VOICE=en_US-ryan-medium
ENV PIPER_MODEL_ONNX=/data/voices/en_US-ryan-medium.onnx
ENV PIPER_MODEL_JSON=/data/voices/en_US-ryan-medium.onnx.json

# IMPORTANT: server.py reads PIPER_MODEL
ENV PIPER_MODEL=/data/voices/en_US-ryan-medium.onnx

ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "/app/entrypoint.sh"]