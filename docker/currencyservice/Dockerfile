FROM node:20-bullseye

WORKDIR /app

COPY src/currencyservice .

RUN npm install

EXPOSE 7000

CMD ["node", "server.js"]