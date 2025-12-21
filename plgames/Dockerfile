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
# GitHub Actions has full network access, use official rustup directly
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal && \
    echo "✓ Rust installed successfully"
ENV PATH="/root/.cargo/bin:${PATH}"

# Verify Rust installation
RUN rustc --version && cargo --version

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
RUN echo "Generating Prisma client..." && \
    yarn workspace @affine/server exec prisma generate && \
    test -d /workspace/node_modules/.prisma/client && \
    echo "✓ Prisma client generated successfully"

# Build templates
RUN yarn workspace @affine/templates build

# Build backend components (with verbose output for debugging)
RUN echo "Building @affine/reader..." && \
    yarn workspace @affine/reader build && \
    echo "✓ @affine/reader built" && \
    echo "Building @affine/server-native..." && \
    yarn workspace @affine/server-native build && \
    echo "✓ @affine/server-native built" && \
    echo "Building @affine/server..." && \
    yarn workspace @affine/server build && \
    echo "✓ @affine/server built"

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

# Copy Prisma client and generated files (required for runtime)
COPY --from=builder /workspace/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /workspace/node_modules/@prisma ./node_modules/@prisma

# Copy built workspace packages that backend depends on
COPY --from=builder /workspace/packages/common/reader/dist ./node_modules/@affine/reader/dist
COPY --from=builder /workspace/packages/common/reader/package.json ./node_modules/@affine/reader/package.json

# Copy native module package
COPY --from=builder /workspace/packages/backend/native ./node_modules/@affine/server-native

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
