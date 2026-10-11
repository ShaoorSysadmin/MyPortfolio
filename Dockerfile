# Stage 1: Build the Vite application

FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency manifests first for better build caching

COPY package.json package-lock.json ./

# Install exact dependency versions from the lockfile

RUN npm ci

# Copy application source and build the production assets

COPY . .
RUN npm run build

# Stage 2: Serve the static application

FROM nginxinc/nginx-unprivileged:stable-alpine AS runtime

# Copy the compiled frontend into Nginx's web root

COPY --from=builder /app/dist/ /usr/share/nginx/html/

# Configure Nginx for the Vite SPA

COPY nginx.conf /etc/nginx/conf.d/default.conf

# Explicitly run the container as a non-root user
USER root
RUN apk upgrade --no-cache tiff
USER 101

EXPOSE 8080

# Check whether Nginx can serve the application

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
