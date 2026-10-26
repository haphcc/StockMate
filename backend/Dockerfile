# Dockerfile Backend StockMate (FastAPI)
# Owner: TV1 - Phuoc

FROM python:3.13-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements.lock.txt* ./
RUN pip install --upgrade pip && \
    if [ -f requirements.lock.txt ]; then \
        pip install -r requirements.lock.txt; \
    else \
        pip install -r requirements.txt; \
    fi

COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
