FROM --platform=linux/amd64 node:16-slim
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN chown -R nodejs:nodejs /app
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD node healthcheck.js
CMD ["node", "src/server.js"]