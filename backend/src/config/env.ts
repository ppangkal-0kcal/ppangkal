function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export const env = {
  port: Number(process.env.PORT ?? 4000),
  databaseUrl: required('DATABASE_URL', 'postgresql://localhost:5432/ppangkal'),
  jwtSecret: required('JWT_SECRET', 'dev-secret-change-me'),
  tourApi: {
    // 한국관광공사 국문 관광정보 서비스_GW — 서비스키는 공공데이터포털에서 발급.
    // KorService2는 *2 오퍼레이션(locationBasedList2/detailCommon2/detailImage2)과 짝을 이룬다.
    // 신청한 서비스가 v1 오퍼레이션을 제공하지 않아 v2로 통일함 (tourApiService.ts 참고).
    baseUrl: process.env.TOUR_API_BASE_URL ?? 'https://apis.data.go.kr/B551011/KorService2',
    serviceKey: process.env.TOUR_API_SERVICE_KEY ?? '',
  },
  r2: {
    // Cloudflare R2 (S3 호환) — bread_items.image_url을 채우는 관리자용 업로드
    // 스크립트(prisma/scripts/uploadBreadImages.ts) 전용. 런타임 API 라우트에서는 쓰지 않는다
    // (업로드 API 자체가 없음 — 관리자가 로컬에서 스크립트로 직접 올리는 방식).
    accountId: process.env.R2_ACCOUNT_ID ?? '',
    accessKeyId: process.env.R2_ACCESS_KEY_ID ?? '',
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY ?? '',
    bucketName: process.env.R2_BUCKET_NAME ?? 'ppangkal-images',
    publicUrl: process.env.R2_PUBLIC_URL ?? '',
    // 무료 티어 안전장치 (R2 무료: 저장 10GB/월) — imageStorageService.uploadImage()가
    // 매 업로드 전에 이 한도를 검사해서 넘으면 업로드를 거부한다. 기본값은 실제 무료
    // 한도(10GB)보다 낮게 잡은 안전 마진(9GB)이다.
    maxStorageBytes: Number(process.env.R2_MAX_STORAGE_GB ?? 9) * 1024 * 1024 * 1024,
    maxFileSizeBytes: Number(process.env.R2_MAX_FILE_SIZE_MB ?? 10) * 1024 * 1024,
  },
};
