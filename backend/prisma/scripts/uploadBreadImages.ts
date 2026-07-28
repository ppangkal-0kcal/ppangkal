/**
 * 관리자용 1회성 스크립트 — prisma/assets/bread-images/ 에 <bread_item_id>.<ext>
 * 이름으로 넣어둔 이미지 파일들을 Cloudflare R2에 업로드하고, 성공한 것만
 * bread_items.image_url을 그 공개 URL로 갱신한다.
 *
 * 실행: npx tsx prisma/scripts/uploadBreadImages.ts
 * 사전 준비: .env에 R2_ACCOUNT_ID/R2_ACCESS_KEY_ID/R2_SECRET_ACCESS_KEY/
 * R2_BUCKET_NAME/R2_PUBLIC_URL 채워둘 것 (.env.example 참고).
 *
 * bread_item id는 seed.ts 기준 한글이 섞여 있을 수 있는데(예: itm_bak_sungsimdang_소보로빵),
 * 이 스크립트는 파일명을 그대로 id로 취급하므로 파일명도 동일하게 맞춰야 한다.
 */
import { readdirSync, readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { PrismaClient } from '@prisma/client';
import { R2QuotaExceededError, uploadImage } from '../../src/services/imageStorageService';

const ASSETS_DIR = join(__dirname, '..', 'assets', 'bread-images');

const CONTENT_TYPES: Record<string, string> = {
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

async function main() {
  const prisma = new PrismaClient();
  let files: string[];
  try {
    files = readdirSync(ASSETS_DIR);
  } catch {
    console.log(`이미지 폴더가 없습니다: ${ASSETS_DIR} — 건너뜀.`);
    return;
  }

  if (files.length === 0) {
    console.log(`${ASSETS_DIR}에 파일이 없습니다.`);
    return;
  }

  for (const file of files) {
    const ext = extname(file).toLowerCase();
    const contentType = CONTENT_TYPES[ext];
    if (!contentType) {
      console.warn(`건너뜀 (지원 안 하는 확장자): ${file}`);
      continue;
    }

    const breadItemId = file.slice(0, -ext.length);
    const breadItem = await prisma.breadItem.findUnique({ where: { id: breadItemId } });
    if (!breadItem) {
      console.warn(`건너뜀 (DB에 없는 bread_item id): ${breadItemId}`);
      continue;
    }

    const body = readFileSync(join(ASSETS_DIR, file));

    let publicUrl: string;
    try {
      publicUrl = await uploadImage({ key: `bread-items/${breadItemId}${ext}`, body, contentType });
    } catch (err) {
      if (err instanceof R2QuotaExceededError) {
        console.error(`중단: ${err.message}`);
        console.error('무료 티어 안전 한도에 걸려 나머지 파일 업로드를 중단합니다.');
        break;
      }
      throw err;
    }

    await prisma.breadItem.update({ where: { id: breadItemId }, data: { imageUrl: publicUrl } });
    console.log(`업로드 완료: ${breadItemId} -> ${publicUrl}`);
  }

  await prisma.$disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
