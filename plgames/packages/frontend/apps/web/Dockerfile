FROM node:22-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    gcc \
    git \
    curl \
    ca-certificates \
    openssl \
    libssl-dev \
    libc6-dev \
    pkg-config \
    libvips-dev \
    libvips-tools \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for native modules
RUN echo "⏳ Установка Rust (это займет 5-10 минут, пожалуйста подождите)..." && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    echo "✓ Rust установлен"
ENV PATH="/root/.cargo/bin:${PATH}"

RUN corepack enable

# Prisma environment variables
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV PRISMA_CLI_BINARY_TARGETS=native,debian-openssl-3.0.x
ENV PRISMA_QUERY_ENGINE_BINARY=debian-openssl-3.0.x
ENV PRISMA_ENGINES_MIRROR=https://binaries.prisma.sh

COPY . .

# Install dependencies WITHOUT running postinstall (skip init & husky in Docker)
RUN echo "⏳ Установка зависимостей (2800+ пакетов, 10-15 минут)..." && \
    (yarn install --immutable --mode=skip-build 2>/dev/null || yarn install --ignore-scripts) && \
    echo "✓ Зависимости установлены"

# Build frontend
RUN echo "⏳ Сборка frontend (5-10 минут)..." && \
    yarn plgames @affine/web build && \
    echo "✓ Frontend собран"

FROM caddy:2-alpine AS runner

COPY --from=builder /app/packages/frontend/apps/web/dist /usr/share/caddy
COPY --from=builder /app/packages/frontend/apps/web/package.json /usr/share/caddy/package.json
COPY ./packages/frontend/apps/web/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
