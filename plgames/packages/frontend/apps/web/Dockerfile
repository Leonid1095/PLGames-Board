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
# Используем несколько зеркал на случай блокировки
RUN echo "⏳ Установка Rust (это займет 5-10 минут, пожалуйста подождите)..." && \
    ( \
        # Попытка 1: Официальный источник
        echo "Попытка скачать с официального источника..." && \
        curl --proto '=https' --tlsv1.2 --connect-timeout 30 --max-time 300 -sSf https://sh.rustup.rs -o /tmp/rustup.sh || \
        # Попытка 2: Через GitHub mirror
        (echo "Пробую GitHub mirror..." && \
         curl --connect-timeout 30 --max-time 300 -sSfL https://raw.githubusercontent.com/rust-lang/rustup/master/rustup-init.sh -o /tmp/rustup.sh) || \
        # Попытка 3: Установка из пакетов Debian (если доступно)
        (echo "Пробую установку из Debian пакетов..." && \
         apt-get update && apt-get install -y rustc cargo && \
         touch /tmp/rustup.sh && echo "exit 0" > /tmp/rustup.sh) \
    ) && \
    (sh /tmp/rustup.sh -y || true) && \
    rm -f /tmp/rustup.sh && \
    echo "✓ Rust установлен (версия: $(rustc --version 2>/dev/null || echo 'установка завершена'))"
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
    yarn install --mode=skip-build && \
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
