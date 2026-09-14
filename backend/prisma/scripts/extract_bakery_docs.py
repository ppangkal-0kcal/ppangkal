"""
관리자용 데이터 추출 스크립트 — `빵칼_빵집_빵 사진 정리/*.docx`(현장 조사 문서)를 읽어
prisma/data/curated-bakeries.json 과 앱용으로 줄인 사진(prisma/assets/curated-images/)을 만든다.
DB 반영은 importCuratedBakeries.ts가 이 JSON을 읽어서 한다.

실행 (레포 루트 기준):
  pip install pillow
  python backend/prisma/scripts/extract_bakery_docs.py "빵칼_빵집_빵 사진 정리"

문서 형식은 두 가지(수집 요청서 / 데이터 정리본)지만 둘 다 `| DB 필드 | 값 | 비고 |` 표라서
표 행 단위로 읽는다. `name` 행이 나올 때마다 새 레코드가 시작되고, 첫 레코드는 빵집이다.
"""
import io
import json
import os
import re
import sys
import zipfile
from xml.etree import ElementTree as ET

from PIL import Image, ImageOps

W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'
A = '{http://schemas.openxmlformats.org/drawingml/2006/main}'
R = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}'
PIC = '{http://schemas.openxmlformats.org/drawingml/2006/picture}'

HERE = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(HERE, '..', 'data', 'curated-bakeries.json')
IMAGE_DIR = os.path.join(HERE, '..', 'assets', 'curated-images')

MAX_IMAGE_EDGE = 1080
JPEG_QUALITY = 82

# 문서 파일명(키워드) → 빵집 id. 기존 DB에 있던 빵집은 id를 유지해야 tour_stops/food_logs FK와
# tour_content_id가 그대로 이어진다.
BAKERY_IDS = [
    ('성심당', 'bak_sungsimdang'),
    ('몽심', 'bak_mongsim'),
    ('꾸드뱅', 'bak_tourapi_2899345'),
    ('오븐_브라더스', 'bak_ovenbrothers'),
    ('캘리포니아베이커리', 'bak_californiabakery'),
    ('하레하레', 'bak_harehare_dunsan'),
    ('그린베이커리', 'bak_greenbakery'),
    ('나무상자', 'bak_namusangja'),
    ('데_아로즈', 'bak_dearose'),
    ('덴하그', 'bak_denhaag'),
    ('로로네', 'bak_lorone'),
    ('슬로우브레드', 'bak_slowbread'),
    ('오픈오븐', 'bak_openoven'),
    ('콜드버터', 'bak_coldbutter'),
    ('파이룸', 'bak_pieroom'),
    ('하루팡', 'bak_harupang'),
]

# 원본 문서의 명백한 복사·붙여넣기 오류만 바로잡는다 (2026-09-14 확인). 값이 확정되면 문서를 고치고
# 여기서 지울 것.
BAKERY_OVERRIDES = {
    # 문서 좌표가 성심당 본점과 소수점까지 동일. 주소(유성구 대학로 39-10) 기준 근사 좌표 — 실측 확인 필요.
    'bak_pieroom': {'latitude': 36.3589, 'longitude': 127.3448},
    # 리뷰 수가 성심당 본점 값(18,392)과 동일 — 신뢰할 수 없어 비워둔다.
    'bak_denhaag': {'review_count': None, 'name': '덴하그 (Denhaag)'},
}

DESSERT_KEYWORDS =('휘낭시에', '마들렌', '쿠키', '타르트', '케이크', '케익', '슈', '파이', '스콘',
                    '까눌레', '카눌레', '푸딩', '마카롱', '브라우니', '다쿠아즈', '에클레어', '롤')


def cell_text(cell):
    return ' / '.join(''.join(t.text or '' for t in p.iter(W + 't')) for p in cell.iter(W + 'p')).strip(' /')


def cell_images(cell, relmap):
    """문서에 보이는 그대로 재현하기 위한 (파일, 자르기, 회전) — Word는 원본 픽셀은 그대로 두고
    `a:srcRect`(구도 조정 자르기)와 `a:xfrm rot`(회전)을 도형 속성으로만 적용한다."""
    images = []
    for pic in cell.iter(PIC + 'pic'):
        blip = pic.find(f'.//{A}blip')
        if blip is None or blip.get(R + 'embed') not in relmap:
            continue
        src_rect = pic.find(f'.//{A}srcRect')
        crop = {k: int(src_rect.get(k, 0)) for k in ('l', 't', 'r', 'b')} if src_rect is not None else None
        xfrm = pic.find(f'.//{A}xfrm')
        rotation = int(xfrm.get('rot', 0)) / 60000 if xfrm is not None else 0
        images.append({'member': relmap[blip.get(R + 'embed')], 'crop': crop, 'rotation': rotation})
    return images


def read_rows(zf):
    root = ET.fromstring(zf.read('word/document.xml'))
    rels = ET.fromstring(zf.read('word/_rels/document.xml.rels'))
    relmap = {r.get('Id'): 'word/' + r.get('Target') for r in rels}
    for row in root.iter(W + 'tr'):
        cells = list(row.iter(W + 'tc'))
        if len(cells) < 2:
            continue
        yield cell_text(cells[0]), cell_text(cells[1]), (cell_text(cells[2]) if len(cells) > 2 else ''), \
            cell_images(cells[1], relmap)


def parse_int(text):
    # "5,800원", "약 290 kcal", "개당 110(kcal)", "18,392" → 첫 번째 숫자. 템플릿 문구("가격 (원)")는 None.
    m = re.search(r'\d[\d,]*', text or '')
    return int(m.group().replace(',', '')) if m else None


def parse_float(text):
    m = re.search(r'\d+(\.\d+)?', text or '')
    return float(m.group()) if m else None


def clean_bakery_name(name):
    # "몽심 (Mongsim) 본점" → "몽심 본점", "대전 하레하레 둔산점" → "하레하레 둔산점" (전부 대전 매장)
    name = re.sub(r'\s+', ' ', re.sub(r'\([^)]*\)', '', name)).strip()
    return re.sub(r'^대전\s+', '', name)


def save_image(zf, image, out_path):
    with Image.open(io.BytesIO(zf.read(image['member']))) as img:
        img = ImageOps.exif_transpose(img).convert('RGB')
        crop = image['crop']
        if crop:
            # srcRect 값은 각 변에서 잘라낼 비율(1/100000 단위, 음수는 여백 추가라 무시)
            w, h = img.size
            box = (w * max(crop['l'], 0) / 100000, h * max(crop['t'], 0) / 100000,
                   w * (1 - max(crop['r'], 0) / 100000), h * (1 - max(crop['b'], 0) / 100000))
            if box[2] - box[0] > 10 and box[3] - box[1] > 10:
                img = img.crop(tuple(round(v) for v in box))
        rotation = round(image['rotation']) % 360
        if rotation:
            img = img.rotate(-rotation, expand=True)  # Word rot은 시계 방향, PIL은 반시계
        img.thumbnail((MAX_IMAGE_EDGE, MAX_IMAGE_EDGE))
        img.save(out_path, 'JPEG', quality=JPEG_QUALITY, optimize=True, progressive=True)


def bakery_id_for(filename):
    for keyword, bakery_id in BAKERY_IDS:
        if keyword in filename:
            return bakery_id
    raise SystemExit(f'빵집 id 매핑이 없습니다: {filename} — BAKERY_IDS에 추가하세요.')


def extract(docx_path, warnings):
    filename = os.path.basename(docx_path)
    bakery_id = bakery_id_for(filename)
    zf = zipfile.ZipFile(docx_path)

    records = []
    current = None
    for field, value, note, images in read_rows(zf):
        if field == 'name':
            current = {'name': value, 'note_name': note, 'fields': {}, 'notes': {}, 'images': []}
            records.append(current)
        elif current is not None and field in (
                'latitude, longitude', 'latitude', 'longitude', 'address', 'rating', 'review_count',
                'entrance_image_url', 'category', 'price', 'calories', '데이터 출처', 'image_url'):
            current['fields'][field] = value
            current['notes'][field] = note
            if images:
                current['images'] += images

    bakery_rec, bread_recs = records[0], records[1:]
    f = bakery_rec['fields']
    if 'latitude, longitude' in f:
        lat, lng = (float(x) for x in f['latitude, longitude'].split(',')[:2])
    else:
        lat, lng = float(f['latitude']), float(f['longitude'])

    os.makedirs(os.path.join(IMAGE_DIR, bakery_id), exist_ok=True)
    image_files = {}

    def image_for(image, stem):
        # 같은 사진을 같은 구도로 여러 메뉴가 공유하면 파일 하나만 만든다
        key = (image['member'], tuple(sorted((image['crop'] or {}).items())), image['rotation'])
        if key not in image_files:
            rel = f'{bakery_id}/{stem}.jpg'
            save_image(zf, image, os.path.join(IMAGE_DIR, rel))
            image_files[key] = rel
        return image_files[key]

    bakery = {
        'id': bakery_id,
        'name': clean_bakery_name(bakery_rec['name']),
        'latitude': lat,
        'longitude': lng,
        'address': f.get('address', '').strip(),
        'rating': parse_float(f.get('rating')),
        'review_count': parse_int(f.get('review_count')),
        'photo': image_for(bakery_rec['images'][0], 'entrance') if bakery_rec['images'] else None,
        'source_document': filename,
        'bread_items': [],
    }
    bakery.update(BAKERY_OVERRIDES.get(bakery_id, {}))

    seen = set()
    for idx, rec in enumerate(bread_recs, start=1):
        bf, notes = rec['fields'], rec['notes']
        name = rec['name'].strip()
        if not name or name in seen:
            # 같은 이름이 두 번 나오면 먼저 나온 값을 쓴다 (칼로리가 다르면 경고로 남겨 확인 요청).
            warnings.append(f'{bakery["name"]}: 중복 메뉴 "{name}" — 첫 항목 유지, 뒤 항목 '
                            f'(price="{rec["fields"].get("price")}", calories="{rec["fields"].get("calories")}") 무시')
            continue
        price = parse_int(bf.get('price'))
        calories = parse_int(bf.get('calories'))
        if price is None or calories is None:
            warnings.append(f'{bakery["name"]} / {name}: 가격 또는 칼로리 미확인 — 건너뜀 '
                            f'(price="{bf.get("price")}", calories="{bf.get("calories")}")')
            continue
        seen.add(name)

        category = (bf.get('category') or '').strip()
        if not category or '예:' in category:
            category = '디저트' if any(k in name for k in DESSERT_KEYWORDS) else '빵'

        calorie_text = f'{bf.get("calories", "")} {notes.get("calories", "")}'
        source = (bf.get('데이터 출처') or '').strip()
        estimated = '추정' in calorie_text or re.search(r'(^|\s)약\s*\d', calorie_text) is not None
        source_note = '매장 미공개 — 유사 제품 기준 추정치' if estimated else None
        if source:
            source_note = f'{source_note} · 사진: {source}' if source_note else f'사진: {source}'

        bakery['bread_items'].append({
            'id': f'itm_{bakery_id}_{name}',
            'name': name,
            'category': category,
            'price': price,
            'calories': calories,
            'source_grade': 'C' if estimated else 'B',
            'source_note': source_note,
            'image': image_for(rec['images'][0], f'item{idx:02d}') if rec['images'] else None,
        })

    return bakery


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else '빵칼_빵집_빵 사진 정리'
    docs = sorted(os.path.join(src, f) for f in os.listdir(src) if f.endswith('.docx'))
    warnings = []
    bakeries = []
    for doc in docs:
        bakery = extract(doc, warnings)
        bakeries.append(bakery)
        print(f'{bakery["id"]:<24} {bakery["name"]:<20} 메뉴 {len(bakery["bread_items"])}종')

    os.makedirs(os.path.dirname(DATA_PATH), exist_ok=True)
    with open(DATA_PATH, 'w', encoding='utf-8') as fp:
        json.dump({'bakeries': bakeries}, fp, ensure_ascii=False, indent=2)

    print(f'\n총 빵집 {len(bakeries)}곳, 메뉴 {sum(len(b["bread_items"]) for b in bakeries)}종 → {os.path.relpath(DATA_PATH)}')
    for w in warnings:
        print('경고:', w)


if __name__ == '__main__':
    main()
