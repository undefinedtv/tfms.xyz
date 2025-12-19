FROM python:3.12-slim

WORKDIR /app

# Gerekli paketleri kur
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Repo'yu klonla
RUN git clone https://github.com/MarkMCFC/tfms.xyz .

# Python paketlerini kur
RUN pip install --no-cache-dir \
    flask \
    curl-cffi \
    m3u8 \
    gunicorn \
    gevent

# Çevre değişkenleri - Streaming için optimize
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    WORKERS=1 \
    THREADS=4 \
    TIMEOUT=300 \
    WORKER_CLASS=gevent \
    WORKER_CONNECTIONS=50 \
    MAX_REQUESTS=500 \
    MAX_REQUESTS_JITTER=50 \
    GRACEFUL_TIMEOUT=60 \
    KEEPALIVE=75

EXPOSE 7860

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=15s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Gunicorn yapılandırması - Streaming için
CMD exec gunicorn \
    --workers ${WORKERS} \
    --worker-class ${WORKER_CLASS} \
    --worker-connections ${WORKER_CONNECTIONS} \
    --threads ${THREADS} \
    --timeout ${TIMEOUT} \
    --graceful-timeout ${GRACEFUL_TIMEOUT} \
    --keepalive ${KEEPALIVE} \
    --max-requests ${MAX_REQUESTS} \
    --max-requests-jitter ${MAX_REQUESTS_JITTER} \
    --bind 0.0.0.0:7860 \
    --access-logfile - \
    --error-logfile - \
    --log-level warning \
    --limit-request-line 8190 \
    --limit-request-field_size 8190 \
    --preload \
    proxy:app
