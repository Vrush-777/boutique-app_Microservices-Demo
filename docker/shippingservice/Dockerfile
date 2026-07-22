FROM golang:1.25-alpine AS builder

WORKDIR /app

COPY src/shippingservice .

RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -o shipping .

FROM alpine:latest

WORKDIR /app

COPY --from=builder /app/shipping .

EXPOSE 50050

CMD ["./shipping"]