# Stage 1: Build stage
FROM node:20-bullseye-slim AS builder

WORKDIR /app
# Pre-built assets are used to save server memory
COPY . ./
# This check ensures that if the user SCP'd the build folder, we use it.
# If not, we create a placeholder to avoid build failure.
RUN if [ ! -d "build" ]; then \
      mkdir -p build && \
      echo "<html><body><h1>Pre-built folder missing</h1><p>Please SCP the 'build' folder from your local machine.</p></body></html>" > build/index.html; \
    fi

# Stage 2: Production stage
FROM node:20-bullseye-slim

RUN groupadd -g 1001 worklenz && useradd -u 1001 -g worklenz worklenz

RUN apt-get update && apt-get install -y \
    tini \
    curl \
    && npm install -g serve@14.2.1 \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder --chown=worklenz:worklenz /app/build ./build

RUN printf 'window.VITE_API_URL = "";\n' > /app/build/env-config.js && \
    printf 'window.VITE_SOCKET_URL = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_APP_TITLE = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_APP_ENV = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_ENABLE_RECAPTCHA = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_RECAPTCHA_SITE_KEY = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_ENABLE_GOOGLE_LOGIN = "";\n' >> /app/build/env-config.js && \
    printf 'window.VITE_ENABLE_SURVEY_MODAL = "";\n' >> /app/build/env-config.js && \
    chown worklenz:worklenz /app/build/env-config.js

RUN printf '#!/bin/sh\ncat > /app/build/env-config.js << ENVEOF\nwindow.VITE_API_URL = "${VITE_API_URL}";\nwindow.VITE_SOCKET_URL = "${VITE_SOCKET_URL}";\nwindow.VITE_APP_TITLE = "${VITE_APP_TITLE:-Worklenz}";\nwindow.VITE_APP_ENV = "${VITE_APP_ENV:-production}";\nwindow.VITE_ENABLE_RECAPTCHA = "${VITE_ENABLE_RECAPTCHA:-false}";\nwindow.VITE_RECAPTCHA_SITE_KEY = "${VITE_RECAPTCHA_SITE_KEY:-}";\nwindow.VITE_ENABLE_GOOGLE_LOGIN = "${VITE_ENABLE_GOOGLE_LOGIN:-false}";\nwindow.VITE_ENABLE_SURVEY_MODAL = "${VITE_ENABLE_SURVEY_MODAL:-false}";\nENVEOF\n' > /app/env-config.sh && chmod +x /app/env-config.sh

RUN printf '#!/bin/sh\nset -e\necho "Generating runtime environment configuration..."\n/app/env-config.sh\necho "Starting frontend server..."\nexec serve -s /app/build -l 5000 --no-request-logging\n' > /app/start.sh && chmod +x /app/start.sh

RUN chown worklenz:worklenz /app/env-config.sh /app/start.sh

USER worklenz
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD curl -f http://localhost:5000 || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/start.sh"]
