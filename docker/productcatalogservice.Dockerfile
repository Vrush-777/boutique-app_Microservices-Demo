# ==============================================================================
# PRODUCT CATALOG SERVICE DOCKERFILE
# ==============================================================================

FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY src/productcatalogservice/ .
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/server .

FROM alpine:3.18
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/server /app/server
EXPOSE 3550
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3550/health || exit 1
CMD ["/app/server"]