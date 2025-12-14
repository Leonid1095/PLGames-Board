# PLGames Board - Production Dockerfile
# Based on AFFiNE, optimized for deployment in Russia
#
# Stage 1: Build - compiles frontend and backend
# Stage 2: Backend - Node.js server
# Stage 3: Frontend - Caddy static file server

# ============================================
# Stage 1: Build everything inside Docker
# ============================================
FROM node:22-bookworm AS builder

WORKDIR /workspace

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    python3 \
    build-essential \
    curl \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Rust (required for @affine/server-native, needs 1.82+)
# Using mirrors for Russia-friendly access
RUN set -e; \
    export RUSTUP_DIST_SERVER="https://rsproxy.cn" && \
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup" && \
    # Try rsproxy.cn first, then official with retries
    (curl -sSf https://rsproxy.cn/rustup-init.sh -o rustup-init.sh || \
     curl -sSf --retry 3 --retry-delay 5 https://sh.rustup.rs -o rustup-init.sh) && \
    chmod +x rustup-init.sh && \
    sh rustup-init.sh -y --default-toolchain stable --profile minimal && \
    rm rustup-init.sh && \
    # Configure cargo to use sparse protocol (faster, works in Russia)
    mkdir -p ~/.cargo && \
    echo '[source.crates-io]' >> ~/.cargo/config.toml && \
    echo 'replace-with = "ustc"' >> ~/.cargo/config.toml && \
    echo '' >> ~/.cargo/config.toml && \
    echo '[source.ustc]' >> ~/.cargo/config.toml && \
    echo 'registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"' >> ~/.cargo/config.toml
ENV PATH="/root/.cargo/bin:${PATH}"

# Copy source code
COPY . .

# Initialize git (required by build tools)
RUN git config --global user.email "docker@plgames.local" && \
    git config --global user.name "Docker Build" && \
    git init && \
    git add -A && \
    git commit -m "Docker build"

# Enable Corepack and install Yarn
RUN corepack enable && \
    corepack prepare yarn@stable --activate

# Set memory limit and production mode
ENV NODE_OPTIONS="--max-old-space-size=6144"
ENV NODE_ENV=production

# Install dependencies (skip native builds)
RUN yarn install --mode=skip-build

# Generate Prisma client (required for database access)
# Retry up to 3 times in case of network issues
RUN for i in 1 2 3; do \
      yarn workspace @affine/server exec prisma generate && break || \
      (echo "Prisma generate failed, attempt $i/3, retrying in 10s..." && sleep 10); \
    done

# Build templates
RUN yarn workspace @affine/templates build

# Build backend components
RUN yarn workspace @affine/reader build && \
    yarn workspace @affine/server-native build && \
    yarn workspace @affine/server build

# Build frontend with timeout (max 30 minutes)
RUN timeout 1800 yarn plgames build -p @affine/web || \
    (echo "Frontend build timed out after 30 minutes" && exit 1)

# Verify frontend build succeeded
RUN test -d /workspace/packages/frontend/apps/web/dist || \
    (echo "ERROR: Frontend build failed - dist directory not found" && exit 1)

# ============================================
# Stage 2: Runtime - Backend
# ============================================
FROM node:22-bookworm-slim AS backend

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openssl \
    libjemalloc2 \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Enable jemalloc
ENV LD_PRELOAD=libjemalloc.so.2
ENV NODE_ENV=production

# Copy built backend from builder
COPY --from=builder /workspace/packages/backend/server/dist ./dist
COPY --from=builder /workspace/packages/backend/server/schema.prisma ./schema.prisma

# Copy all node_modules from workspace root (Yarn workspaces use hoisting)
COPY --from=builder /workspace/node_modules ./node_modules

# Copy built workspace packages that backend depends on
COPY --from=builder /workspace/packages/common/reader/dist ./node_modules/@affine/reader/dist
COPY --from=builder /workspace/packages/common/reader/package.json ./node_modules/@affine/reader/package.json

# Copy native module package
COPY --from=builder /workspace/packages/backend/native ./node_modules/@affine/server-native

# Copy generated Prisma client
COPY --from=builder /workspace/node_modules/.prisma ./node_modules/.prisma

EXPOSE 3010

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
  CMD curl -f http://localhost:3010/api/healthz || exit 1

CMD ["node", "./dist/main.js"]

# ============================================
# Stage 3: Runtime - Frontend
# ============================================
FROM caddy:2-alpine AS frontend

# Copy built frontend from builder
COPY --from=builder /workspace/packages/frontend/apps/web/dist /usr/share/caddy
COPY --from=builder /workspace/packages/frontend/apps/web/package.json /usr/share/caddy/package.json
COPY --from=builder /workspace/packages/frontend/apps/web/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
