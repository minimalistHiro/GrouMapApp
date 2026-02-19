"""
Nano Banana Pro (Gemini 3 Pro Image) 画像生成スクリプト
Usage: python3 generate_image.py "プロンプト" "出力パス" "アスペクト比" "画像サイズ" ["参考画像パス"]
"""
import sys
import os

from google import genai
from google.genai import types
from PIL import Image


def generate_image(
    prompt: str,
    output_path: str,
    aspect_ratio: str = "1:1",
    image_size: str = "2K",
    reference_image_path: str = None,
):
    client = genai.Client()

    if reference_image_path and os.path.exists(reference_image_path):
        ref_image = Image.open(reference_image_path)
        contents = [prompt, ref_image]
    else:
        contents = prompt

    response = client.models.generate_content(
        model="gemini-3-pro-image-preview",
        contents=contents,
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
            image_config=types.ImageConfig(
                aspect_ratio=aspect_ratio,
                image_size=image_size,
            ),
        ),
    )

    saved = False
    for part in response.parts:
        if part.text is not None:
            print(part.text)
        elif image := part.as_image():
            os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)
            image.save(output_path)
            print(f"画像を保存しました: {output_path}")
            saved = True

    if not saved:
        print("エラー: 画像が生成されませんでした。プロンプトを変えて再試行してください。")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 generate_image.py <prompt> [output_path] [aspect_ratio] [image_size]")
        print("  aspect_ratio: 1:1, 16:9, 9:16, 4:3, 3:4")
        print("  image_size: 1K, 2K, 4K")
        sys.exit(1)

    prompt = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else "generated_image.png"
    aspect_ratio = sys.argv[3] if len(sys.argv) > 3 else "1:1"
    image_size = sys.argv[4] if len(sys.argv) > 4 else "2K"
    reference_image_path = sys.argv[5] if len(sys.argv) > 5 else None

    generate_image(prompt, output_path, aspect_ratio, image_size, reference_image_path)
