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
    gunicorn[gevent]

# Çevre değişkenleri
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    PORT=7860

EXPOSE 7860

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Basitleştirilmiş başlatma
CMD exec gunicorn \
    --bind 0.0.0.0:7860 \
    --workers 1 \
    --worker-class gevent \
    --worker-connections 100 \
    --timeout 300 \
    --graceful-timeout 30 \
    --keep-alive 5 \
    --log-level info \
    --access-logfile - \
    --error-logfile - \
    proxy:app
