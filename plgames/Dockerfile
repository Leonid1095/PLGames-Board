# Multi-stage Dockerfile for PLGames Board
# Stage 1: Build
# Stage 2: Runtime

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
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . .

# Initialize git (required by build tools)
RUN git init && \
    git add -A && \
    git commit -m "Docker build" || true

# Enable Corepack and install Yarn
RUN corepack enable && \
    corepack prepare yarn@stable --activate

# Set memory limit
ENV NODE_OPTIONS="--max-old-space-size=6144"

# Install dependencies (skip native builds)
RUN yarn install --mode=skip-build

# Generate Prisma client
RUN yarn workspace @affine/server exec prisma generate || true

# Build templates
RUN yarn workspace @affine/templates build

# Build backend components
RUN yarn workspace @affine/reader build && \
    yarn workspace @affine/server build

# Build frontend
RUN yarn plgames build -p @affine/web

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
COPY --from=builder /workspace/packages/backend/server/node_modules ./node_modules
COPY --from=builder /workspace/packages/common/reader/dist ./node_modules/@affine/reader/dist
COPY --from=builder /workspace/packages/common/reader/package.json ./node_modules/@affine/reader/package.json

# Copy root node_modules for workspace dependencies
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
