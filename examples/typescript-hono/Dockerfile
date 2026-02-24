FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/registration.json ./
COPY --from=builder /app/dashboard.html ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.well-known ./.well-known
EXPOSE 3000
CMD ["npm", "start"]
