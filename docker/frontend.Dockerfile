# ==============================================================================
# FRONTEND DOCKERFILE
# ==============================================================================
# Builds the frontend service (Go application)
# ==============================================================================

# Stage 1: Build stage
# We compile the Go application
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy source code
COPY src/frontend/ .

# Download dependencies
RUN go mod download

# Build the application
# -o /app/server = output file name
# . = compile current directory
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

# ==============================================================================
# Stage 2: Runtime stage
# We create a small image with just the compiled binary
# This is much smaller than including Go compiler
# ==============================================================================

FROM alpine:3.18

# Install ca-certificates for HTTPS
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy compiled binary from builder
COPY --from=builder /app/server /app/server

# Expose port (must match application)
EXPOSE 8080

# Health check (optional but recommended)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the application
CMD ["/app/server"]