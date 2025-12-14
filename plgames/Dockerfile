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
# Using multiple mirrors for reliability (Russia, China, official)
RUN set -e; \
    RUSTUP_INSTALLED=0; \
    # Try multiple sources in order of preference for Russia/China
    for MIRROR in \
        "https://rsproxy.cn/rustup-init.sh|https://rsproxy.cn|https://rsproxy.cn/rustup" \
        "https://sh.rustup.rs|https://static.rust-lang.org|https://static.rust-lang.org/rustup" \
        "https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup-init.sh|https://mirrors.tuna.tsinghua.edu.cn/rustup|https://mirrors.tuna.tsinghua.edu.cn/rustup"; \
    do \
        INIT_URL=$(echo $MIRROR | cut -d'|' -f1); \
        DIST_SERVER=$(echo $MIRROR | cut -d'|' -f2); \
        UPDATE_ROOT=$(echo $MIRROR | cut -d'|' -f3); \
        echo "Trying Rust installation from: $INIT_URL"; \
        export RUSTUP_DIST_SERVER="$DIST_SERVER"; \
        export RUSTUP_UPDATE_ROOT="$UPDATE_ROOT"; \
        if curl -sSfL --connect-timeout 30 --max-time 120 "$INIT_URL" -o rustup-init.sh; then \
            chmod +x rustup-init.sh && \
            sh rustup-init.sh -y --default-toolchain stable --profile minimal && \
            rm rustup-init.sh && \
            RUSTUP_INSTALLED=1 && \
            echo "✓ Successfully installed Rust from $INIT_URL" && \
            break; \
        else \
            echo "✗ Failed to download from $INIT_URL, trying next mirror..."; \
            rm -f rustup-init.sh; \
        fi; \
    done; \
    if [ $RUSTUP_INSTALLED -eq 0 ]; then \
        echo "ERROR: Failed to install Rust from all mirrors"; \
        exit 1; \
    fi; \
    # Configure cargo to use USTC mirror (China, works in Russia)
    mkdir -p ~/.cargo && \
    echo '[source.crates-io]' >> ~/.cargo/config.toml && \
    echo 'replace-with = "ustc"' >> ~/.cargo/config.toml && \
    echo '' >> ~/.cargo/config.toml && \
    echo '[source.ustc]' >> ~/.cargo/config.toml && \
    echo 'registry = "sparse+https://mirrors.ustc.edu.cn/crates.io-index/"' >> ~/.cargo/config.toml && \
    echo '' >> ~/.cargo/config.toml && \
    echo '[net]' >> ~/.cargo/config.toml && \
    echo 'git-fetch-with-cli = true' >> ~/.cargo/config.toml
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
# Using multiple mirrors for Prisma engines (Russia/China friendly)
# CRITICAL: Download engines BEFORE running prisma generate to avoid network issues
RUN set -e; \
    # Get Prisma version and commit hash
    PRISMA_VERSION=$(yarn workspace @affine/server exec prisma --version 2>/dev/null | grep -oP 'prisma\s*:\s*\K[\d.]+' || echo "6.8.2") && \
    PRISMA_HASH=$(yarn workspace @affine/server exec prisma --version 2>/dev/null | grep -oP '(?<=Prisma Engines  : )\S+' | head -1 || echo "latest") && \
    echo "Prisma version: $PRISMA_VERSION (hash: $PRISMA_HASH)" && \
    \
    # Create Prisma cache directory
    mkdir -p /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x && \
    ENGINE_DOWNLOADED=0; \
    \
    # Try multiple sources for query engine
    for URL in \
      "https://binaries.prisma.sh/all_commits/$PRISMA_HASH/debian-openssl-3.0.x/libquery_engine.so.node.gz" \
      "https://binaries.prisma.sh/all_commits/latest/debian-openssl-3.0.x/libquery_engine.so.node.gz" \
      "https://github.com/nicksrandall/prisma-engines-prebuilt/releases/download/latest/libquery_engine-debian-openssl-3.0.x.so.node.gz"; \
    do \
      echo "Trying to download Prisma query engine from: $URL" && \
      if curl -sSfL --connect-timeout 30 --max-time 180 --retry 2 -o /tmp/query_engine.gz "$URL" 2>&1; then \
        if gunzip -c /tmp/query_engine.gz > /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x/libquery_engine-debian-openssl-3.0.x.so.node 2>&1; then \
          chmod +x /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x/libquery_engine-debian-openssl-3.0.x.so.node && \
          ENGINE_DOWNLOADED=1 && \
          echo "✓ Successfully downloaded query engine from $URL" && \
          rm -f /tmp/query_engine.gz && \
          break; \
        else \
          echo "✗ Failed to decompress query engine"; \
          rm -f /tmp/query_engine.gz; \
        fi; \
      else \
        echo "✗ Failed to download from $URL"; \
        rm -f /tmp/query_engine.gz; \
      fi; \
    done; \
    \
    # Also try to download schema engine (sometimes needed)
    for URL in \
      "https://binaries.prisma.sh/all_commits/$PRISMA_HASH/debian-openssl-3.0.x/schema-engine-debian-openssl-3.0.x.gz" \
      "https://binaries.prisma.sh/all_commits/latest/debian-openssl-3.0.x/schema-engine-debian-openssl-3.0.x.gz"; \
    do \
      if curl -sSfL --connect-timeout 30 --max-time 180 --retry 2 -o /tmp/schema_engine.gz "$URL" 2>&1; then \
        if gunzip -c /tmp/schema_engine.gz > /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x/schema-engine-debian-openssl-3.0.x 2>&1; then \
          chmod +x /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x/schema-engine-debian-openssl-3.0.x && \
          echo "✓ Downloaded schema engine" && \
          rm -f /tmp/schema_engine.gz && \
          break; \
        fi; \
      fi; \
      rm -f /tmp/schema_engine.gz; \
    done; \
    \
    if [ $ENGINE_DOWNLOADED -eq 0 ]; then \
      echo "⚠ WARNING: Could not pre-download Prisma engines!"; \
      echo "Prisma will try to download during 'generate' which may fail in Russia"; \
    else \
      echo "✓ Prisma engines cached successfully"; \
      ls -lh /root/.cache/prisma/$PRISMA_HASH/debian-openssl-3.0.x/; \
    fi

# Generate Prisma client with offline mode (uses pre-downloaded engines)
# Set environment to use cached engines and skip downloading
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV PRISMA_SKIP_DOWNLOAD=1
RUN set -e; \
    PRISMA_GENERATED=0; \
    echo "Checking for pre-downloaded Prisma engines..."; \
    ls -R /root/.cache/prisma/ || echo "No engines in cache yet"; \
    \
    for i in 1 2 3 4 5; do \
      echo "Attempting Prisma generate (attempt $i/5)..."; \
      # Run prisma generate with relaxed network requirements
      if timeout 300 yarn workspace @affine/server exec prisma generate 2>&1; then \
        PRISMA_GENERATED=1 && \
        echo "✓ Prisma client generated successfully" && \
        break; \
      else \
        EXIT_CODE=$?; \
        echo "✗ Prisma generate failed on attempt $i/5 (exit code: $EXIT_CODE)"; \
        \
        # If engine download failed, try to work around it
        if [ $i -eq 1 ]; then \
          echo "Checking Prisma engines cache structure..."; \
          find /root/.cache/prisma -type f -name "*query_engine*" 2>/dev/null || true; \
        fi; \
        \
        if [ $i -lt 5 ]; then \
          echo "Retrying in 10 seconds..."; \
          sleep 10; \
        fi; \
      fi; \
    done; \
    \
    if [ $PRISMA_GENERATED -eq 0 ]; then \
      echo ""; \
      echo "====== PRISMA GENERATION FAILED ======"; \
      echo "ERROR: Failed to generate Prisma client after 5 attempts"; \
      echo ""; \
      echo "This is likely due to network issues downloading Prisma engines from Russia."; \
      echo ""; \
      echo "Diagnostic information:"; \
      echo "  - Prisma cache contents:"; \
      ls -R /root/.cache/prisma/ || echo "    Cache is empty"; \
      echo ""; \
      echo "  - Available mirrors:"; \
      echo "    1. https://binaries.prisma.sh (official)"; \
      echo "    2. https://github.com/nicksrandall/prisma-engines-prebuilt"; \
      echo ""; \
      echo "Suggested solutions:"; \
      echo "  1. Retry the build (network may be temporarily down)"; \
      echo "  2. Check internet connection"; \
      echo "  3. Try using a VPN"; \
      echo ""; \
      exit 1; \
    fi; \
    \
    # Verify Prisma client was generated
    if [ ! -d /workspace/node_modules/.prisma/client ]; then \
      echo "ERROR: Prisma client directory not found after generation"; \
      exit 1; \
    fi; \
    echo "✓ Prisma client verification passed"

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
