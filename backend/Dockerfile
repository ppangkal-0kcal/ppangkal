# 빵칼 백엔드 운영 이미지 — Render/Railway/Fly/Cloud Run 어디든 같은 이미지로 뜬다.
# DB(Supabase)·이미지(R2)·TourAPI는 전부 외부 서비스라 컨테이너는 상태가 없다.
#
# 마이그레이션은 부팅 시 자동 실행하지 않는다 — 공유 Supabase DB 스키마를 배포할 때마다
# 건드리지 않도록, 스키마 변경이 있을 때만 로컬에서 `npx prisma migrate deploy`를 직접 돌린다
# (DEPLOYMENT.md 참고).

FROM node:22-bookworm-slim AS build
WORKDIR /app
# Prisma 엔진이 OpenSSL을 찾는다 — slim 이미지엔 없음
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
COPY package.json package-lock.json ./
RUN npm ci
COPY prisma ./prisma
RUN npx prisma generate
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/*
ENV NODE_ENV=production
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
# prisma CLI(devDependency)는 런타임에 없으므로, 빌드 단계에서 생성한 클라이언트를 그대로 가져온다
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/dist ./dist
COPY prisma/schema.prisma ./prisma/schema.prisma

USER node
EXPOSE 4000
CMD ["node", "dist/server.js"]
