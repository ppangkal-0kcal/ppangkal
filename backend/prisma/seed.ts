import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// 빵집/메뉴 원천 데이터는 현장 조사 문서에서 추출한 prisma/data/curated-bakeries.json 하나다
// (prisma/scripts/extract_bakery_docs.py). 시드는 빈 DB를 채우는 용도라 기존 행은 덮어쓰지 않고
// (update: {}), 사진 URL도 넣지 않는다 — 실제 DB 반영과 R2 사진 연결은
// prisma/scripts/importCuratedBakeries.ts가 담당한다.
interface CuratedData {
  bakeries: {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    address: string;
    rating: number | null;
    review_count: number | null;
    bread_items: {
      id: string;
      name: string;
      category: string;
      price: number;
      calories: number;
      source_grade: string;
      source_note: string | null;
    }[];
  }[];
}

// 문서에 없는 운영 정보 — TourAPI content_id는 실제 조회로 확인한 값만 둔다 (이름 자동 매칭 금지).
const EXTRA_BAKERY_FIELDS: Record<string, { tourContentId?: string; openingHours?: string }> = {
  bak_sungsimdang: { tourContentId: '1796079', openingHours: '08:00-22:00' },
  bak_tourapi_2899345: { tourContentId: '2899345' },
};

async function main() {
  const { bakeries } = JSON.parse(
    readFileSync(join(__dirname, 'data', 'curated-bakeries.json'), 'utf-8'),
  ) as CuratedData;

  let itemCount = 0;
  for (const bakery of bakeries) {
    await prisma.bakery.upsert({
      where: { id: bakery.id },
      update: {},
      create: {
        id: bakery.id,
        name: bakery.name,
        latitude: bakery.latitude,
        longitude: bakery.longitude,
        address: bakery.address,
        rating: bakery.rating,
        reviewCount: bakery.review_count,
        ...EXTRA_BAKERY_FIELDS[bakery.id],
      },
    });

    for (const item of bakery.bread_items) {
      await prisma.breadItem.upsert({
        where: { bakeryId_name: { bakeryId: bakery.id, name: item.name } },
        update: {},
        create: {
          id: item.id,
          bakeryId: bakery.id,
          name: item.name,
          category: item.category,
          price: item.price,
          calories: item.calories,
          sourceGrade: item.source_grade,
          sourceNote: item.source_note,
        },
      });
      itemCount++;
    }
  }

  console.log(`Seed complete: ${bakeries.length} bakeries, ${itemCount} bread items.`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
