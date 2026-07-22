FROM golang:1.21-alpine AS builder

WORKDIR /app

COPY src/productcatalogservice .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o productcatalog .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/productcatalog .

EXPOSE 3550

CMD ["./productcatalog"]