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
    PYTHONUNBUFFERED=1

EXPOSE 7860

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=15s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Gunicorn yapılandırması - Streaming için (düzeltilmiş)
CMD exec gunicorn \
    --workers 1 \
    --worker-class gevent \
    --worker-connections 50 \
    --threads 4 \
    --timeout 300 \
    --graceful-timeout 60 \
    --keep-alive 75 \
    --max-requests 500 \
    --max-requests-jitter 50 \
    --bind 0.0.0.0:7860 \
    --access-logfile - \
    --error-logfile - \
    --log-level warning \
    --limit-request-line 8190 \
    --limit-request-field_size 8190 \
    --preload \
    proxy:app
