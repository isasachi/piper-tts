FROM python:3.11-slim

# Install deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget ca-certificates tar \
  && rm -rf /var/lib/apt/lists/*

# Download Piper binary release (Linux x86_64) and extract
ARG PIPER_TAG=2023.11.14-2
RUN wget -O /tmp/piper.tar.gz "https://github.com/rhasspy/piper/releases/download/${PIPER_TAG}/piper_linux_x86_64.tar.gz" \
  && tar -xzf /tmp/piper.tar.gz -C /usr/local/bin \
  && chmod +x /usr/local/bin/piper \
  && rm -f /tmp/piper.tar.gz

# Temporary sanity check
RUN /usr/local/bin/piper --help

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
