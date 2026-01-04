# Use Node.js 20 as the base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache python3 make g++

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY src/ ./src/
COPY prompts.json ./prompts.json
COPY prompts.example.json ./prompts.example.json

# Copy build script and other necessary files
COPY ./*.js ./
COPY ./*.json ./

# Create build directory
RUN mkdir -p build

# Build the application
RUN npm run build

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# Change ownership of the app directory
RUN chown -R nextjs:nodejs /app
USER nextjs

# Expose port 8001 for HTTP transport
EXPOSE 8001

# Set the default command to start the server
CMD ["node", "build/index.js"]
