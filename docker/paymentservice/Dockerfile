FROM node:20-alpine

WORKDIR /app

COPY src/paymentservice .

RUN npm install

EXPOSE 50051

CMD ["node", "index.js"]