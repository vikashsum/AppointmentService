# Multi-stage build for appointmentservice (Node.js/Express)

# Stage 1: Build and test
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm ci --only=development

# Copy application source
COPY . .

# Run linting and tests
RUN npm run lint
RUN npm run test

# Build output directory (if needed, adjust based on your build process)
RUN echo "Build stage completed"


# Stage 2: Production runtime
FROM node:18-alpine

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application from builder stage
COPY --from=builder /app/src ./src
COPY --from=builder /app/.sequelizerc ./

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

ENV NODE_ENV=production

CMD ["npm", "start"]
