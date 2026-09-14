"""
빵칼 앱 아이콘 생성 — 로그인 화면 브랜드 마크(갈색 원 + 빵 아이콘)와 같은 디자인.
디자이너 아이콘이 나오면 이 스크립트 대신 그 이미지로 교체하면 된다.

실행 (ppangkal-frontend 폴더에서):
  pip install pillow
  python tool/generate_app_icon.py

생성물:
  - Android 기존 아이콘   android/app/src/main/res/mipmap-*/ic_launcher.png (원형 배지)
  - Android 적응형 아이콘 mipmap-anydpi-v26/ic_launcher.xml + ic_launcher_foreground.png + 배경색
  - iOS                   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png (불투명 정사각형)

글리프: Flutter SDK의 Material Icons 폰트(Apache License 2.0) `bakery_dining` (U+E0C9).
"""
import os
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.environ.get('MATERIAL_ICONS_FONT', r'C:\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf')
GLYPH = '\ue0c9'

BROWN = (122, 83, 35, 255)  # 앱 primary 계열 (#7A5323)
CREAM = (255, 246, 234, 255)  # AppBackground 상단 색 (#FFF6EA)
SUPERSAMPLE = 4


def draw_glyph(canvas: Image.Image, box_size: int, glyph_ratio: float, color):
    """글리프의 실제 잉크 영역을 캔버스 중앙에, 긴 변이 box_size × glyph_ratio가 되게 그린다.

    아이콘 폰트의 글자 박스는 그림보다 훨씬 커서(위아래 여백 포함) textbbox로 맞추면
    위로 치우치고 작아진다 — 크게 그린 뒤 실제 픽셀 경계로 잘라 붙인다.
    """
    probe_size = 1024
    probe = Image.new('L', (probe_size * 2, probe_size * 2), 0)
    ImageDraw.Draw(probe).text((probe_size // 2, probe_size // 2), GLYPH,
                               font=ImageFont.truetype(FONT, probe_size), fill=255)
    mask = probe.crop(probe.getbbox())

    target = box_size * glyph_ratio
    scale = target / max(mask.size)
    mask = mask.resize((max(1, round(mask.width * scale)), max(1, round(mask.height * scale))), Image.LANCZOS)

    size = canvas.size[0]
    fill = Image.new('RGBA', mask.size, color)
    canvas.paste(fill, ((size - mask.width) // 2, (size - mask.height) // 2), mask)


def render(px: int, kind: str) -> Image.Image:
    big = px * SUPERSAMPLE
    if kind == 'legacy':  # 투명 배경 위 원형 배지 (구형 런처)
        img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(img).ellipse((0, 0, big - 1, big - 1), fill=BROWN)
        draw_glyph(img, big, 0.58, CREAM)
    elif kind == 'foreground':  # 적응형 전경: 108dp 캔버스, 글리프는 안전영역(66dp) 안
        img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        draw_glyph(img, big, 0.46, CREAM)
    elif kind == 'ios':  # iOS는 투명도 불가 — 정사각형 꽉 채움, 모서리는 OS가 깎는다
        img = Image.new('RGBA', (big, big), BROWN)
        draw_glyph(img, big, 0.62, CREAM)
        img = img.convert('RGB')
    else:
        raise ValueError(kind)
    return img.resize((px, px), Image.LANCZOS)


def main():
    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, scale in densities.items():
        folder = os.path.join(res, f'mipmap-{name}')
        os.makedirs(folder, exist_ok=True)
        render(int(48 * scale), 'legacy').save(os.path.join(folder, 'ic_launcher.png'), optimize=True)
        render(int(108 * scale), 'foreground').save(os.path.join(folder, 'ic_launcher_foreground.png'), optimize=True)

    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<!-- tool/generate_app_icon.py로 생성 -->\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )
    values = os.path.join(res, 'values')
    with open(os.path.join(values, 'ic_launcher_background.xml'), 'w', encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            '    <color name="ic_launcher_background">#7A5323</color>\n'
            '</resources>\n'
        )

    appiconset = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    for filename in os.listdir(appiconset):
        m = re.match(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$', filename)
        if not m:
            continue
        px = round(float(m.group(1)) * int(m.group(2)))
        render(px, 'ios').save(os.path.join(appiconset, filename), optimize=True)

    print('아이콘 생성 완료: Android(기존+적응형), iOS')


if __name__ == '__main__':
    main()
