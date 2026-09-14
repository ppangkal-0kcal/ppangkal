/**
 * 관리자용 스크립트 — prisma/data/curated-bakeries.json(현장 조사 문서에서 추출,
 * extract_bakery_docs.py 참고)을 DB에 반영하고, 사진을 R2에 올려 photo_url/image_url을 채운다.
 *
 * 실행: npx tsx --env-file=.env prisma/scripts/importCuratedBakeries.ts [--skip-images]
 *   --skip-images: 업로드는 하지 않고 R2에 이미 있는 사진만 연결한다 (로컬 검증 DB 채우기용).
 *
 * 여러 번 실행해도 결과가 같다(멱등):
 * - 빵집/빵은 id 기준 upsert. 기존 빵집(성심당·몽심·꾸드뱅)은 id를 유지해서 tour_stops/food_logs FK와
 *   tour_content_id가 그대로 이어진다. JSON에 없는 필드(opening_hours 등)는 덮어쓰지 않는다.
 * - JSON에서 빠진 기존 메뉴는 삭제하지 않고 is_available=false로 내린다 — food_logs가 참조할 수 있다.
 * - R2 키는 파일 경로로 고정(curated/<bakeryId>/<file>)이라 재업로드는 같은 오브젝트를 덮어쓴다.
 *   이미 같은 크기로 올라가 있으면 건너뛴다.
 */
import { readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import { ListObjectsV2Command, S3Client } from '@aws-sdk/client-s3';
import { PrismaClient } from '@prisma/client';
import { env } from '../../src/config/env';
import { R2QuotaExceededError, uploadImage } from '../../src/services/imageStorageService';

interface CuratedBreadItem {
  id: string;
  name: string;
  category: string;
  price: number;
  calories: number;
  source_grade: 'A' | 'B' | 'C';
  source_note: string | null;
  image: string | null;
}

interface CuratedBakery {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  address: string;
  rating: number | null;
  review_count: number | null;
  photo: string | null;
  bread_items: CuratedBreadItem[];
}

const DATA_PATH = join(__dirname, '..', 'data', 'curated-bakeries.json');
const IMAGE_DIR = join(__dirname, '..', 'assets', 'curated-images');
const KEY_PREFIX = 'curated/';

const prisma = new PrismaClient();

async function listExistingObjectSizes(): Promise<Map<string, number>> {
  const client = new S3Client({
    region: 'auto',
    endpoint: `https://${env.r2.accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId: env.r2.accessKeyId, secretAccessKey: env.r2.secretAccessKey },
  });
  const sizes = new Map<string, number>();
  let token: string | undefined;
  do {
    const res = await client.send(
      new ListObjectsV2Command({ Bucket: env.r2.bucketName, Prefix: KEY_PREFIX, ContinuationToken: token }),
    );
    for (const obj of res.Contents ?? []) {
      if (obj.Key) sizes.set(obj.Key, obj.Size ?? 0);
    }
    token = res.IsTruncated ? res.NextContinuationToken : undefined;
  } while (token);
  return sizes;
}

/** 상대 경로(bak_x/item01.jpg) → 공개 URL. 업로드를 건너뛰는 모드면 기존 URL 규칙으로만 만든다. */
function createImageUploader(skipImages: boolean, existing: Map<string, number>) {
  const cache = new Map<string, string>();
  let quotaHit = false;

  return async (relativePath: string | null): Promise<string | undefined> => {
    if (!relativePath || quotaHit) return undefined;
    const key = `${KEY_PREFIX}${relativePath}`;
    const publicUrl = `${env.r2.publicUrl}/${key}`;
    if (cache.has(key)) return cache.get(key);

    const filePath = join(IMAGE_DIR, relativePath);
    const size = statSync(filePath).size;
    if (skipImages || existing.get(key) === size) {
      if (skipImages && !existing.has(key)) return undefined;
      cache.set(key, publicUrl);
      return publicUrl;
    }

    try {
      const url = await uploadImage({ key, body: readFileSync(filePath), contentType: 'image/jpeg' });
      cache.set(key, url);
      return url;
    } catch (err) {
      if (err instanceof R2QuotaExceededError) {
        console.error(`R2 안전 한도로 사진 업로드 중단: ${err.message}`);
        quotaHit = true;
        return undefined;
      }
      throw err;
    }
  };
}

async function main() {
  const skipImages = process.argv.includes('--skip-images');
  const { bakeries } = JSON.parse(readFileSync(DATA_PATH, 'utf-8')) as { bakeries: CuratedBakery[] };

  // --skip-images still links photos that are already in R2 (e.g. filling a local verification DB
  // after the real import) — it only skips uploading.
  const hasR2 = Boolean(env.r2.accountId);
  const existing = hasR2 ? await listExistingObjectSizes() : new Map<string, number>();
  const imageUrlFor = createImageUploader(skipImages || !hasR2, existing);

  let itemCount = 0;
  let retiredCount = 0;

  for (const bakery of bakeries) {
    const photoUrl = await imageUrlFor(bakery.photo);
    const bakeryData = {
      name: bakery.name,
      latitude: bakery.latitude,
      longitude: bakery.longitude,
      address: bakery.address,
      rating: bakery.rating,
      reviewCount: bakery.review_count,
      ...(photoUrl ? { photoUrl } : {}),
    };
    await prisma.bakery.upsert({
      where: { id: bakery.id },
      create: { id: bakery.id, ...bakeryData },
      update: bakeryData,
    });

    for (const item of bakery.bread_items) {
      const imageUrl = await imageUrlFor(item.image);
      const itemData = {
        category: item.category,
        price: item.price,
        calories: item.calories,
        sourceGrade: item.source_grade,
        sourceNote: item.source_note,
        isAvailable: true,
        ...(imageUrl ? { imageUrl } : {}),
      };
      // (bakery_id, name) unique 제약이 있으므로 이름 기준으로 찾는다 — 예전 시드가 다른 id 규칙으로
      // 같은 이름을 넣어뒀어도 새 행을 만들다 충돌하지 않고 기존 행을 갱신한다.
      await prisma.breadItem.upsert({
        where: { bakeryId_name: { bakeryId: bakery.id, name: item.name } },
        create: { id: item.id, bakeryId: bakery.id, name: item.name, ...itemData },
        update: itemData,
      });
      itemCount++;
    }

    const retired = await prisma.breadItem.updateMany({
      where: { bakeryId: bakery.id, name: { notIn: bakery.bread_items.map((i) => i.name) }, isAvailable: true },
      data: { isAvailable: false },
    });
    retiredCount += retired.count;

    console.log(`반영: ${bakery.name} (${bakery.bread_items.length}종${retired.count ? `, 판매중지 ${retired.count}` : ''})`);
  }

  console.log(`\n빵집 ${bakeries.length}곳, 메뉴 ${itemCount}종 반영. 목록에서 빠진 기존 메뉴 ${retiredCount}종은 is_available=false.`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
