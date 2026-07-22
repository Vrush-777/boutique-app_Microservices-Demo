FROM node:20-bullseye

WORKDIR /app

COPY src/paymentservice .

RUN npm install

EXPOSE 50051

CMD ["node", "index.js"]