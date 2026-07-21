#!/usr/bin/env python3
"""実物のガパオライス写真から商品だけを切り抜き、透過PNGで保存する。"""

from io import BytesIO
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tmp" / "pdf_deps"))

from PIL import Image
from rembg import new_session, remove


SOURCE_PATH = ROOT / "generated_images" / "gapao_original.png"
OUTPUT_PATH = ROOT / "generated_images" / "gapao_product_cutout.png"


def main() -> None:
    if not SOURCE_PATH.exists():
        raise FileNotFoundError(f"入力画像がありません: {SOURCE_PATH}")

    session = new_session("u2net")
    result = remove(
        SOURCE_PATH.read_bytes(),
        session=session,
        alpha_matting=True,
        alpha_matting_foreground_threshold=235,
        alpha_matting_background_threshold=15,
        alpha_matting_erode_size=8,
    )
    image = Image.open(BytesIO(result)).convert("RGBA")
    bbox = image.getchannel("A").getbbox()
    if not bbox:
        raise ValueError("商品を検出できませんでした。")
    image = image.crop(bbox)
    image.save(OUTPUT_PATH)
    print(OUTPUT_PATH)


if __name__ == "__main__":
    main()
