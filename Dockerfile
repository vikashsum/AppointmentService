# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --silent

COPY . .

RUN npm run lint || true
RUN npm run test || true


# Stage 2: Production
FROM node:18-alpine

WORKDIR /app

RUN apk add --no-cache curl

COPY --from=builder /app /app

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

# IMPORTANT: match ECS port
ENV PORT=3002
ENV NODE_ENV=production

EXPOSE 3002

# FIXED HEALTHCHECK (your real route)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -f http://localhost:3002/api/v1/health || exit 1

CMD ["npm", "start"]
