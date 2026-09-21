# Use the official Node.js 22 (LTS) image as a parent image, pinned by digest
FROM node:22-alpine@sha256:b6f26b36c8ff49624cfdac716b8ea1138d606df02586a77d364bb5536a634f85 AS builder

# Set the working directory in the container to /app
WORKDIR /app

# Copy package.json and package-lock.json into the container
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --ignore-scripts

# Copy the rest of the application code into the container
COPY src/ ./src/
COPY tsconfig.json ./

# Build the project for Docker
RUN npm run build

# Use a minimal node image as the base image for running
FROM node:22-alpine@sha256:b6f26b36c8ff49624cfdac716b8ea1138d606df02586a77d364bb5536a634f85 AS runner

WORKDIR /app

# Copy compiled code from the builder stage
COPY --from=builder /app/smithery ./smithery
COPY package.json package-lock.json ./

# Install only production dependencies
RUN npm ci --production --ignore-scripts

# The Exa API key must be provided at run time: docker run -e EXA_API_KEY=...
ENV PORT=3000
USER node

# Expose the port the app runs on
EXPOSE 3000

# Run the application
ENTRYPOINT ["node", "smithery/shttp/index.cjs"]
