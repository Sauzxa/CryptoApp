# Multi-stage build for React dashboard
FROM node:20-alpine as build

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Set environment variables for Vite build
ENV NODE_ENV=production
ENV VITE_CLOUDINARY_CLOUD_NAME=dtsmryrbe
ENV VITE_CLOUDINARY_UPLOAD_PRESET=crypto-immobilier-preset

# Build the application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine

# Copy built app from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Use default nginx configuration (no custom config needed)
# The global nginx will handle routing

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
