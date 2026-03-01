FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates && rm -rf /var/lib/apt/lists/*

# Download Piper binary release or install it your preferred way.
# Simplest: grab piper binary and place at /usr/local/bin/piper
# NOTE: For production, pin a version and checksum-verify.
RUN wget -O /usr/local/bin/piper https://github.com/rhasspy/piper/releases/download/v1.2.0/piper_linux_x86_64 \
 && chmod +x /usr/local/bin/piper

WORKDIR /app
COPY app/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app/server.py /app/server.py

ENV PIPER_BIN=/usr/local/bin/piper
ENV PIPER_MODEL=/voices/en_US-ryan-medium.onnx

# Must bind to $PORT on platforms like Railway; also fine on VPS.
ENV PORT=8080
EXPOSE 8080

CMD ["sh", "-c", "uvicorn server:app --host 0.0.0.0 --port ${PORT}"]
