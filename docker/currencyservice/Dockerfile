FROM node:20-alpine

WORKDIR /app

COPY src/currencyservice .

RUN npm install

EXPOSE 7000

CMD ["node", "server.js"]