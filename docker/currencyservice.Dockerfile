# ==============================================================================
# CURRENCY SERVICE DOCKERFILE (Node.js)
# ==============================================================================

FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY src/currencyservice/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY src/currencyservice/ .

EXPOSE 7000

# Run application
CMD ["node", "index.js"]