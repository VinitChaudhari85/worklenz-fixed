# Stage 1: Build stage
FROM node:20-bullseye-slim AS builder

RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . ./
RUN npm run build
RUN echo "$(date '+%Y-%m-%d %H:%M:%S')" > build/RELEASE_VERSION

# Stage 2: Production stage
FROM node:20-bullseye-slim

RUN groupadd -r worklenz && useradd -r -g worklenz worklenz

RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    tini \
    ca-certificates \
    libvips \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder --chown=worklenz:worklenz /app/build ./build
COPY --from=builder --chown=worklenz:worklenz /app/build/RELEASE_VERSION ./release
COPY --from=builder --chown=worklenz:worklenz /app/worklenz-email-templates ./worklenz-email-templates

RUN mkdir -p /app/logs && chown -R worklenz:worklenz /app

USER worklenz
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3000/public/health || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "build/bin/www.js"]

