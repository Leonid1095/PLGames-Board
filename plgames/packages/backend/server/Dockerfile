FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies for building (python3, make, g++, etc. might be needed for native modules)
RUN apk add --no-cache python3 make g++ git curl

# Install Rust (required for affine_native / icu_provider)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Enable corepack
RUN corepack enable

# Copy root package.json and lockfile
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn

# Copy workspace packages
COPY packages/backend/server ./packages/backend/server
COPY packages/backend/native ./packages/backend/native
COPY packages/common/infra ./packages/common/infra
COPY packages/common/env ./packages/common/env
COPY packages/common/y-octo ./packages/common/y-octo
COPY tools ./tools

# We need to copy everything because of workspace dependencies... 
# For a monorepo, it's often easier to copy everything and let .dockerignore handle exclusions
COPY . .

# Install dependencies
RUN yarn install

# Build backend
RUN yarn plgames @affine/server build

# Prune dev dependencies (optional, but good for size)
# RUN yarn workspaces focus --production @affine/server

FROM node:22-alpine AS runner

WORKDIR /app

RUN apk add --no-cache openssl

COPY --from=builder /app/packages/backend/server/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/backend/server/package.json ./package.json

# Copy native modules if they are not in node_modules (depending on how they are built)
# Usually they are in node_modules after install

# Create stub static files for selfhosted mode
# In our architecture, frontend is served by Caddy container, not backend
# But backend's StaticFilesResolver still expects these files to exist
RUN mkdir -p static/admin static/mobile && \
    echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/"></head></html>' > static/selfhost.html && \
    echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/"></head></html>' > static/admin/selfhost.html && \
    echo '<!DOCTYPE html><html><head><meta http-equiv="refresh" content="0;url=/"></head></html>' > static/mobile/selfhost.html

ENV NODE_ENV=production
ENV PORT=3010

EXPOSE 3010

CMD ["node", "dist/main.js"]
