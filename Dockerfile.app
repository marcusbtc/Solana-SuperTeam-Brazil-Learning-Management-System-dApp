FROM node:20-alpine AS dependencies

WORKDIR /workspace
COPY package.json package-lock.json ./
COPY onchain-academy/app/package.json ./onchain-academy/app/package.json
COPY onchain-academy/backend/package.json ./onchain-academy/backend/package.json
RUN npm ci

FROM node:20-alpine AS builder

ARG NEXT_PUBLIC_API_BASE_URL
ARG NEXT_PUBLIC_SITE_URL
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}
ENV NEXT_PUBLIC_SITE_URL=${NEXT_PUBLIC_SITE_URL}

WORKDIR /workspace
COPY --from=dependencies /workspace/node_modules ./node_modules
COPY . .
RUN test -n "$NEXT_PUBLIC_API_BASE_URL" && test -n "$NEXT_PUBLIC_SITE_URL"
RUN npm run build:app

FROM node:20-alpine AS runtime

ENV NODE_ENV=production
WORKDIR /workspace
COPY --from=builder /workspace/package.json /workspace/package-lock.json ./
COPY --from=builder /workspace/node_modules ./node_modules
COPY --from=builder /workspace/onchain-academy/app/package.json ./onchain-academy/app/package.json
COPY --from=builder /workspace/onchain-academy/app/.next ./onchain-academy/app/.next
COPY --from=builder /workspace/onchain-academy/app/public ./onchain-academy/app/public
COPY --from=builder /workspace/onchain-academy/app/next.config.mjs ./onchain-academy/app/next.config.mjs

USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ["wget", "--quiet", "--tries=1", "--spider", "http://127.0.0.1:3000/api/health"]

CMD ["npm", "--workspace", "onchain-academy/app", "run", "start"]
