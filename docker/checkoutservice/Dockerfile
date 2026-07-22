FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY src/checkoutservice .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o checkout .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/checkout .

EXPOSE 5050

CMD ["./checkout"]