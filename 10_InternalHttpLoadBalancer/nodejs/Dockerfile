FROM node:10

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

copy . .

Expose 3000

CMD ["node", "index.js"]
