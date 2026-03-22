# Stage 1: Build the application
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies separately for caching
COPY package.json package-lock.json ./
RUN npm ci --legacy-peer-deps

# Copy the rest of the code and build
COPY . .
RUN npm run build

# Stage 2: Production environment
FROM node:20-alpine AS runner

WORKDIR /app

# Install tini **before switching to non-root**
RUN apk add --no-cache tini

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set environment to production
ENV NODE_ENV=production

# Copy only necessary files from the builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Correct permissions so non-root user can read/write
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Use tini as PID 1 for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

# Start the application
CMD ["npm", "start"]