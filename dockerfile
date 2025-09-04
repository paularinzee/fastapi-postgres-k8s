# ---- ✳️ Builder stage: compile wheels so runtime stays slim
FROM python:3.10-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# ✅ needed only if you're using psycopg2 (not psycopg2-binary)
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ✅ only copy requirements first so Docker cache works
COPY requirements.txt .

# ✅ build deps into wheels (faster installs in runtime)
RUN pip wheel --wheel-dir /wheels -r requirements.txt


# ---- ✅ Runtime stage: clean image
FROM python:3.10-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOST=0.0.0.0 \
    PORT=8080

# ✅ runtime deps only (libpq5 for psycopg2, curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ✅ non-root user (security best practice)
RUN addgroup --system app && adduser --system --ingroup app app

# ✅ copy wheels + install
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

# ✅ copy project code (based on your structure.txt)
COPY api ./api
COPY items ./items
COPY orders ./orders
COPY users ./users
COPY models ./models
COPY database ./database
