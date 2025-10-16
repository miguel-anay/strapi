FROM node:20-alpine

# Install dependencies for building native modules
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    sqlite

# Set working directory
WORKDIR /opt/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev

# Copy application files
COPY . .

# Build the admin panel
ENV NODE_ENV=production
# Increase Node.js memory limit for build
ENV NODE_OPTIONS="--max-old-space-size=2048"
RUN npm run build

# Expose Strapi port
EXPOSE 1337

# Start Strapi
CMD ["npm", "run", "start"]
