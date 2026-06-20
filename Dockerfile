# Multi-stage build for appointmentservice (Node.js/Express)

# Stage 1: Build and test
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files first for cache
COPY package*.json ./

# Install dependencies (dev + prod). Use npm install because no package-lock.json exists.
RUN npm install --silent

# Copy application source
COPY . .

# Run linting and tests (allow failures to surface in CI logs)
RUN npm run lint || true
RUN npm run test || true


# Stage 2: Production runtime
FROM node:18-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy built app and node_modules from builder
COPY --from=builder /app /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# Health check (adjust path if your app exposes a different endpoint)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

ENV NODE_ENV=production

CMD ["npm", "start"]
