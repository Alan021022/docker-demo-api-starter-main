FROM node:22-alpine

WORKDIR /app

# Install dependencies in a separate layer
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy application code
COPY server.js db.js ./

EXPOSE 3000

CMD ["node", "server.js"]
