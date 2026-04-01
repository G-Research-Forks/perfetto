# Multi-stage Dockerfile for building and serving Perfetto UI

#########
# Stage 1: Builder - Install dependencies and build the UI
FROM debian:bookworm-slim AS builder

# Install system dependencies required for building
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        git \
        python3-pip \
        python3-venv \
        && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /workspace

# Copy the entire repository
COPY . .

# Initialize git config (required by install-build-deps for git clean)
RUN git config --global init.defaultBranch main && \
    git config --global user.email "docker@build" && \
    git config --global user.name "Docker Build"

# Install build dependencies
RUN ./tools/install-build-deps --ui

# Build the UI
RUN ./ui/build

#########
# Stage 2: Runtime - Serve the built UI with nginx
FROM nginxinc/nginx-unprivileged

# Copy built UI from builder stage
COPY --from=builder /workspace/out/ui/ui/dist /usr/share/nginx/html
