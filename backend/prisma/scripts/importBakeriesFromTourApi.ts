/**
 * 관리자용 1회성 스크립트 — 한국관광공사 TourAPI에서 대전 지역 "카페/전통찻집"
 * (contentTypeId=39, cat1=A05/cat2=A0502/cat3=A05020900) 후보를 가져와서,
 * 소개글(overview)에 빵집 관련 키워드가 있는 곳만 걸러 bakeries 테이블에 추가한다.
 *
 * 배경: TourAPI 구 분류체계엔 "베이커리/제과" 카테고리가 아예 없고, 신 분류체계
 * (lclsSystm3=FD030100 제과)로 조회해도 대전엔 2곳(성심당·꾸드뱅)뿐이라 커버리지가
 * 매우 낮다. 그래서 상위 카테고리인 "카페/전통찻집" 전체(대전 기준 26곳)를 훑어서
 * 업체 소개글 텍스트로 2차 필터링하는 방식을 쓴다 — 이름만 보고 자동으로 넣지 않는다.
 *
 * 주의: 여기서 추가되는 bakeries 행은 bread_items가 하나도 없다 (TourAPI는 메뉴/가격/
 * 칼로리 데이터를 안 준다). 실제로 앱에서 빵을 골라 칼로리를 추적하려면 seed.ts처럼
 * 사람이 직접 bread_items를 조사해서 추가해야 한다 — 이 스크립트는 "빵집 존재 자체"와
 * TourAPI 소개글/사진 보강까지만 채워준다.
 *
 * 실행: npx tsx prisma/scripts/importBakeriesFromTourApi.ts
 */
import { PrismaClient } from '@prisma/client';
import { env } from '../../src/config/env';

const prisma = new PrismaClient();

const BAKERY_KEYWORDS = ['빵', '베이커리', '제과', '바게트', '크루아상', '식빵'];

function buildUrl(operation: string, params: Record<string, string | number>): string {
  const url = new URL(`${env.tourApi.baseUrl}/${operation}`);
  url.searchParams.set('serviceKey', env.tourApi.serviceKey);
  url.searchParams.set('MobileOS', 'ETC');
  url.searchParams.set('MobileApp', 'ppangkal');
  url.searchParams.set('_type', 'json');
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, String(value));
  }
  return url.toString();
}

function toArray<T>(items: unknown): T[] {
  if (!items || items === '') return [];
  const wrapped = items as { item: T[] | T };
  return Array.isArray(wrapped.item) ? wrapped.item : [wrapped.item];
}

interface CandidateItem {
  contentid: string;
  title: string;
  addr1: string;
  mapx: string;
  mapy: string;
}

async function fetchCandidates(): Promise<CandidateItem[]> {
  const res = await fetch(
    buildUrl('areaBasedList2', {
      contentTypeId: 39,
      areaCode: 3, // 대전
      cat1: 'A05',
      cat2: 'A0502',
      cat3: 'A05020900', // 카페/전통찻집 — TourAPI엔 베이커리 전용 카테고리가 없어 이 상위분류를 씀
      numOfRows: 100,
      pageNo: 1,
      arrange: 'A',
    }),
  );
  if (!res.ok) throw new Error(`areaBasedList2 요청 실패: ${res.status}`);
  const data = await res.json();
  return toArray<CandidateItem>(data.response?.body?.items);
}

async function fetchOverview(contentId: string): Promise<string> {
  const res = await fetch(buildUrl('detailCommon2', { contentId }));
  if (!res.ok) throw new Error(`detailCommon2 요청 실패 (${contentId}): ${res.status}`);
  const data = await res.json();
  const [common] = toArray<{ overview?: string }>(data.response?.body?.items);
  return common?.overview ?? '';
}

function looksLikeBakery(title: string, overview: string): boolean {
  const text = `${title} ${overview}`;
  return BAKERY_KEYWORDS.some((keyword) => text.includes(keyword));
}

async function main() {
  const candidates = await fetchCandidates();
  console.log(`후보 ${candidates.length}곳 조회됨. 소개글 확인 중...\n`);

  const existing = await prisma.bakery.findMany({
    where: { tourContentId: { not: null } },
    select: { tourContentId: true },
  });
  const existingContentIds = new Set(existing.map((b) => b.tourContentId));

  let added = 0;
  for (const candidate of candidates) {
    if (existingContentIds.has(candidate.contentid)) {
      console.log(`건너뜀 (이미 DB에 있음): ${candidate.title}`);
      continue;
    }

    const overview = await fetchOverview(candidate.contentid);
    if (!looksLikeBakery(candidate.title, overview)) {
      console.log(`제외 (빵집으로 보이지 않음): ${candidate.title}`);
      continue;
    }

    await prisma.bakery.create({
      data: {
        id: `bak_tourapi_${candidate.contentid}`,
        name: candidate.title,
        latitude: Number(candidate.mapy),
        longitude: Number(candidate.mapx),
        address: candidate.addr1,
        tourContentId: candidate.contentid,
      },
    });
    console.log(`추가됨: ${candidate.title} (${candidate.addr1})`);
    added += 1;
  }

  console.log(`\n완료 — ${added}곳 추가됨 (전체 후보 ${candidates.length}곳 중).`);
  await prisma.$disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
