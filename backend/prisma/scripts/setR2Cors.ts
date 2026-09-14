/**
 * 관리자용 1회성 스크립트 — R2 버킷에 CORS 규칙(GET/HEAD, 모든 origin)을 설정한다.
 *
 * 왜 필요한가: Flutter 웹은 이미지를 <img>가 아니라 XHR로 받아 캔버스에 그리기 때문에
 * 응답에 Access-Control-Allow-Origin이 없으면 사진이 전부 깨진다. 모바일 앱은 영향 없음.
 * 사진은 이미 공개 URL이라 읽기 전용 CORS를 여는 것으로 노출 범위가 늘지는 않는다.
 *
 * 실행: npx tsx --env-file=.env prisma/scripts/setR2Cors.ts
 *
 * 주의: 버킷 설정 변경 권한(Admin Read & Write)이 있는 R2 API 토큰이 필요하다. 현재 .env의
 * 객체 읽기/쓰기 토큰으로는 AccessDenied (2026-09-14 확인) — Cloudflare 대시보드
 * R2 > 버킷 > Settings > CORS Policy에서 같은 규칙을 넣어도 된다. 그 전까지 앱은
 * 웹에서 <img> 대체 경로로 사진을 표시한다 (lib/widgets/network_photo.dart).
 */
import { GetBucketCorsCommand, PutBucketCorsCommand, S3Client } from '@aws-sdk/client-s3';
import { env } from '../../src/config/env';

async function main() {
  const client = new S3Client({
    region: 'auto',
    endpoint: `https://${env.r2.accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId: env.r2.accessKeyId, secretAccessKey: env.r2.secretAccessKey },
  });

  await client.send(
    new PutBucketCorsCommand({
      Bucket: env.r2.bucketName,
      CORSConfiguration: {
        CORSRules: [
          {
            AllowedOrigins: ['*'],
            AllowedMethods: ['GET', 'HEAD'],
            AllowedHeaders: ['*'],
            MaxAgeSeconds: 86400,
          },
        ],
      },
    }),
  );

  const current = await client.send(new GetBucketCorsCommand({ Bucket: env.r2.bucketName }));
  console.log('CORS 설정 완료:', JSON.stringify(current.CORSRules));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
