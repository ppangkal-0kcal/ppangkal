import { ListObjectsV2Command, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { env } from '../config/env';

// Cloudflare R2 is S3-compatible — same SDK, just a different endpoint/region.
// 런타임 요청 경로에서는 쓰이지 않는다: 이미지 업로드는 관리자가 로컬에서
// prisma/scripts/uploadBreadImages.ts를 실행하는 방식뿐이라 이 클라이언트는
// 그 스크립트에서만 import된다.
const client = new S3Client({
  region: 'auto',
  endpoint: `https://${env.r2.accountId}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: env.r2.accessKeyId,
    secretAccessKey: env.r2.secretAccessKey,
  },
});

/** 업로드가 무료 티어 안전 한도(env.r2.maxStorageBytes/maxFileSizeBytes)를 넘어서 거부됐을 때 던진다. */
export class R2QuotaExceededError extends Error {}

/**
 * 버킷에 현재 들어있는 오브젝트들의 총 바이트 수. R2는 사용량을 실시간으로 조회하는
 * 과금 API가 따로 없어서, S3 호환 ListObjectsV2로 직접 합산한다 — 이 프로젝트 규모
 * (빵 사진 수십~수백 개)에서는 페이지네이션 몇 번이면 충분하다.
 */
export async function getBucketUsageBytes(): Promise<number> {
  let totalBytes = 0;
  let continuationToken: string | undefined;

  do {
    const res = await client.send(
      new ListObjectsV2Command({
        Bucket: env.r2.bucketName,
        ContinuationToken: continuationToken,
      }),
    );
    totalBytes += (res.Contents ?? []).reduce((sum, obj) => sum + (obj.Size ?? 0), 0);
    continuationToken = res.IsTruncated ? res.NextContinuationToken : undefined;
  } while (continuationToken);

  return totalBytes;
}

export async function uploadImage(params: {
  key: string;
  body: Buffer;
  contentType: string;
}): Promise<string> {
  if (params.body.byteLength > env.r2.maxFileSizeBytes) {
    throw new R2QuotaExceededError(
      `파일이 너무 큽니다 (${params.body.byteLength}B > 허용 ${env.r2.maxFileSizeBytes}B): ${params.key}`,
    );
  }

  // R2 무료 티어는 저장 10GB/월까지다. 실제 과금 전에 코드에서 먼저 막기 위해,
  // 매 업로드 전 현재 버킷 사용량 + 이번 파일 크기가 설정한 안전 한도
  // (기본 9GB, R2_MAX_STORAGE_GB)를 넘으면 업로드 자체를 거부한다.
  const currentUsage = await getBucketUsageBytes();
  if (currentUsage + params.body.byteLength > env.r2.maxStorageBytes) {
    throw new R2QuotaExceededError(
      `R2 저장 용량 안전 한도 초과로 업로드를 막았습니다. ` +
        `현재 사용량 ${(currentUsage / 1024 / 1024).toFixed(1)}MB, ` +
        `한도 ${(env.r2.maxStorageBytes / 1024 / 1024).toFixed(1)}MB.`,
    );
  }

  await client.send(
    new PutObjectCommand({
      Bucket: env.r2.bucketName,
      Key: params.key,
      Body: params.body,
      ContentType: params.contentType,
    }),
  );

  return `${env.r2.publicUrl}/${params.key}`;
}
