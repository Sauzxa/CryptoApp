# Use Node.js 20 LTS as base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY CryptoBack/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy TypeScript configuration
COPY CryptoBack/tsconfig.json ./

# Copy source code
COPY CryptoBack/src/ ./src/

# Copy scripts for database initialization
COPY scripts/ ./scripts/
COPY CryptoBack/start.sh ./


# Make scripts executable and fix line endings
RUN chmod +x ./scripts/*.sh ./start.sh && \
    sed -i 's/\r$//' ./scripts/*.sh && \
    sed -i 's/\r$//' ./start.sh

# Install netcat for MongoDB health check
RUN apk add --no-cache netcat-openbsd

# Install dev dependencies for building
RUN npm install --save-dev typescript ts-node

# Build the application
RUN npm run build

# Remove dev dependencies to reduce image size
RUN npm prune --production

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Start the application with database initialization
CMD ["sh", "-c", "echo '🚀 Starting backend...' && while ! nc -z mongo 27017; do sleep 1; done && echo '✅ MongoDB ready!' && echo '🎯 Starting app...' && npm start"]
