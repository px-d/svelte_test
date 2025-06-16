# Stage 1: Build the application
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy package.json and bun.lockb to leverage Docker cache
COPY package.json bun.lock ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy the rest of the application source code
COPY . .

# Build the application
# This will use the "build" script from your package.json
RUN bun run build

# Stage 2: Create the production image
FROM node:20-alpine AS runner

WORKDIR /app

# Set NODE_ENV to production
ENV NODE_ENV=production
# Set a default port, can be overridden by PORT env var at runtime
ENV PORT=3000

# Create a non-root user and group for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the build output from the builder stage
# SvelteKit's adapter-node (often used by adapter-auto) outputs to a 'build' directory
COPY --from=builder --chown=appuser:appgroup /app/build ./build

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE ${PORT}

# Command to run the application
# The entry point for SvelteKit adapter-node is typically build/index.js
CMD ["node", "build/index.js"]
