"""
빵칼 앱 아이콘 생성 — 디자이너 아이콘(리포지토리 루트 `빵칼_아이콘.png`, 512x512 불투명)에서
Android/iOS 런처 아이콘을 만든다.

실행 (ppangkal-frontend 폴더에서):
  pip install pillow
  python tool/generate_app_icon.py

  다른 원본을 쓰려면: APP_ICON_SOURCE=경로 python tool/generate_app_icon.py

생성물:
  - Android 기존 아이콘   android/app/src/main/res/mipmap-*/ic_launcher.png (원형 배지)
  - Android 적응형 아이콘 mipmap-anydpi-v26/ic_launcher.xml + ic_launcher_foreground.png + 배경색
  - iOS                   ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png (불투명 정사각형)

원본은 단색 배경 위에 그림이 올라간 형태라, 배경색은 모서리 픽셀에서 읽고 그림 영역은
배경색과 다른 픽셀의 경계로 잘라낸다 — 적응형 아이콘 전경은 그렇게 잘라낸 그림만 쓴다
(런처 마스크가 캔버스 가장자리를 잘라내므로 원본을 그대로 넣으면 그림이 잘린다).
"""
import os
import re
from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.environ.get('APP_ICON_SOURCE', os.path.join(os.path.dirname(ROOT), '빵칼_아이콘.png'))

# 배경색과 이만큼도 차이 없는 픽셀은 배경으로 본다 (JPEG 잔여 노이즈·그라데이션 흡수).
CONTENT_TOLERANCE = 20
SUPERSAMPLE = 2

# 그림이 차지하는 비율. 적응형 전경은 108dp 캔버스 기준이라 66dp 안전영역(0.61) 안쪽에 둔다.
# 기존 아이콘은 원형 배지라 내접 정사각형(0.707)보다 작아야 그림이 원 밖으로 삐져나오지 않는다.
LEGACY_CONTENT_RATIO = 0.68
FOREGROUND_CONTENT_RATIO = 0.58


def load_source() -> tuple[Image.Image, tuple[int, int, int]]:
    """원본 이미지와 배경색을 돌려준다."""
    if not os.path.exists(SOURCE):
        raise SystemExit(f'원본 아이콘을 찾을 수 없습니다: {SOURCE}\nAPP_ICON_SOURCE 환경변수로 경로를 지정하세요.')
    img = Image.open(SOURCE).convert('RGBA')
    if img.width != img.height:
        raise SystemExit(f'정사각형 이미지가 필요합니다 (현재 {img.width}x{img.height}).')
    background = img.convert('RGB').getpixel((1, 1))
    return img, background


def crop_content(img: Image.Image, background: tuple[int, int, int]) -> Image.Image:
    """배경색만 있는 여백을 잘라낸 그림. 배경을 투명으로 바꾸지는 않는다 —
    그림 안에도 배경색과 같은 색이 있을 수 있어 색상 기반 제거는 구멍을 낸다."""
    diff = ImageChops.difference(img.convert('RGB'), Image.new('RGB', img.size, background)).convert('L')
    box = diff.point(lambda v: 255 if v > CONTENT_TOLERANCE else 0).getbbox()
    return img.crop(box) if box else img


def paste_centered(canvas: Image.Image, content: Image.Image, ratio: float) -> None:
    """content의 긴 변이 캔버스 × ratio가 되도록 줄여 가운데에 붙인다."""
    size = canvas.size[0]
    scale = (size * ratio) / max(content.size)
    resized = content.resize(
        (max(1, round(content.width * scale)), max(1, round(content.height * scale))),
        Image.LANCZOS,
    )
    canvas.paste(resized, ((size - resized.width) // 2, (size - resized.height) // 2), resized)


def render(px: int, kind: str, content: Image.Image, background: tuple[int, int, int], source: Image.Image) -> Image.Image:
    big = px * SUPERSAMPLE
    if kind == 'legacy':  # 투명 배경 위 원형 배지 (적응형을 모르는 구형 런처)
        img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        ImageDraw.Draw(img).ellipse((0, 0, big - 1, big - 1), fill=(*background, 255))
        paste_centered(img, content, LEGACY_CONTENT_RATIO)
    elif kind == 'foreground':  # 적응형 전경: 108dp 캔버스, 그림은 안전영역 안. 배경은 별도 색 레이어.
        img = Image.new('RGBA', (big, big), (0, 0, 0, 0))
        paste_centered(img, content, FOREGROUND_CONTENT_RATIO)
    elif kind == 'ios':  # iOS는 투명도 불가 — 원본 여백 그대로 쓰고 모서리는 OS가 깎는다
        img = source.resize((big, big), Image.LANCZOS).convert('RGB')
    else:
        raise ValueError(kind)
    return img.resize((px, px), Image.LANCZOS)


def main():
    source, background = load_source()
    content = crop_content(source, background)
    hex_background = '#%02X%02X%02X' % background

    res = os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res')
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    for name, scale in densities.items():
        folder = os.path.join(res, f'mipmap-{name}')
        os.makedirs(folder, exist_ok=True)
        render(int(48 * scale), 'legacy', content, background, source).save(
            os.path.join(folder, 'ic_launcher.png'), optimize=True)
        render(int(108 * scale), 'foreground', content, background, source).save(
            os.path.join(folder, 'ic_launcher_foreground.png'), optimize=True)

    anydpi = os.path.join(res, 'mipmap-anydpi-v26')
    os.makedirs(anydpi, exist_ok=True)
    # <monochrome>은 넣지 않는다 — 테마 아이콘은 단색 실루엣이라야 하는데 이 그림은
    # 실루엣으로 만들면 식빵 덩어리 하나로 뭉개진다.
    with open(os.path.join(anydpi, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<!-- tool/generate_app_icon.py로 생성 -->\n'
            '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <background android:drawable="@color/ic_launcher_background"/>\n'
            '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
            '</adaptive-icon>\n'
        )
    values = os.path.join(res, 'values')
    with open(os.path.join(values, 'ic_launcher_background.xml'), 'w', encoding='utf-8') as f:
        f.write(
            '<?xml version="1.0" encoding="utf-8"?>\n'
            '<resources>\n'
            f'    <color name="ic_launcher_background">{hex_background}</color>\n'
            '</resources>\n'
        )

    appiconset = os.path.join(ROOT, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    for filename in os.listdir(appiconset):
        m = re.match(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png$', filename)
        if not m:
            continue
        px = round(float(m.group(1)) * int(m.group(2)))
        render(px, 'ios', content, background, source).save(os.path.join(appiconset, filename), optimize=True)

    print(f'아이콘 생성 완료 (원본: {SOURCE}, 배경색 {hex_background}): Android(기존+적응형), iOS')


if __name__ == '__main__':
    main()
