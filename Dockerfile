# U APP — static site + Kaggle Android build engine
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --no-audit --no-fund
COPY . .
# Optional build-time overrides. Firebase falls back to the project config in
# src/data/catalog.ts, so the build never fails when these are absent.
ARG VITE_UAPP_UPI_ID=""
ARG VITE_UAPP_UPI_NAME=""
ARG VITE_UAPP_ADS_ENDPOINT=""
ENV VITE_UAPP_UPI_ID=$VITE_UAPP_UPI_ID \
    VITE_UAPP_UPI_NAME=$VITE_UAPP_UPI_NAME \
    VITE_UAPP_ADS_ENDPOINT=$VITE_UAPP_ADS_ENDPOINT
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production PORT=8080 DATA_DIR=/tmp/uapp-data
COPY --from=build /app/dist ./dist
COPY server ./server
COPY kaggle ./kaggle
RUN mkdir -p /tmp/uapp-data/sources /tmp/uapp-data/artifacts
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:${PORT}/api/health >/dev/null || exit 1
CMD ["node", "server/index.mjs"]
