"""
Recraft AI 画像生成スクリプト
Usage: python3 generate_recraft_image.py "プロンプト" "出力パス" [オプション]

対応モデル:
  recraftv2         - ラスター (icon スタイル対応)
  recraftv2_vector  - ベクター/SVG (icon スタイル対応)
  recraftv3         - ラスター
  recraftv3_vector  - ベクター/SVG
  recraftv4         - ラスター (高品質、スタイル指定不可)
  recraftv4_vector  - ベクター/SVG (高品質、スタイル指定不可)

環境変数:
  RECRAFT_API_TOKEN - Recraft AI APIトークン (必須)
                      取得先: https://app.recraft.ai/profile/api
"""
import sys
import os
import argparse
import json
import requests

API_URL = "https://external.api.recraft.ai/v1/images/generations"

# V4 モデルはスタイル指定不可
MODELS_WITHOUT_STYLE = {"recraftv4", "recraftv4_vector"}

VALID_STYLES = {
    "realistic_image",
    "digital_illustration",
    "vector_illustration",
    "icon",
}

ICON_SUBSTYLES = {
    "outline",
    "colored_outline",
    "colored_shape",
    "doodle",
    "gradient_outline",
    "gradient_shape",
    "broken_line",
    "offset_doodle",
    "offset_fill",
    "pictogram",
}

VALID_SIZES = [
    "square_hd",
    "square",
    "portrait_4_3",
    "portrait_16_9",
    "landscape_4_3",
    "landscape_16_9",
    "1024x1024",
    "1280x1024",
    "1024x1280",
    "1536x1024",
    "1024x1536",
]


def get_api_token():
    """環境変数からAPIトークンを取得する"""
    token = os.environ.get("RECRAFT_API_TOKEN")
    if not token:
        print("エラー: RECRAFT_API_TOKEN が設定されていません。")
        print()
        print("APIトークンの取得手順:")
        print("  1. https://app.recraft.ai/profile/api にアクセス")
        print("  2. アカウントを作成/ログイン")
        print("  3. APIトークンを生成")
        print("  4. ~/.zshrc に以下を追加:")
        print('     export RECRAFT_API_TOKEN="your-token-here"')
        print("  5. source ~/.zshrc を実行")
        sys.exit(1)
    return token


def parse_colors(color_str):
    """カラー文字列をAPI形式に変換する

    入力形式: "255,107,53" (単色) or "255,107,53;255,255,255" (複数色)
    出力形式: [{"rgb": [255, 107, 53]}, ...]
    """
    if not color_str:
        return None

    colors = []
    for color in color_str.split(";"):
        parts = color.strip().split(",")
        if len(parts) != 3:
            print(f"警告: 無効なカラー形式 '{color}' をスキップします (正しい形式: R,G,B)")
            continue
        try:
            rgb = [int(p.strip()) for p in parts]
            if all(0 <= v <= 255 for v in rgb):
                colors.append({"rgb": rgb})
            else:
                print(f"警告: RGB値は0-255の範囲で指定してください: '{color}'")
        except ValueError:
            print(f"警告: 無効なカラー値 '{color}' をスキップします")

    return colors if colors else None


def build_request_body(prompt, model, style, substyle, colors, size, response_format):
    """APIリクエストボディを構築する"""
    body = {
        "prompt": prompt,
        "model": model,
        "response_format": response_format,
    }

    if size:
        body["size"] = size

    # V4 モデルはスタイル指定不可
    if model not in MODELS_WITHOUT_STYLE and style:
        body["style"] = style
        if substyle:
            body["substyle"] = substyle

    # カラー指定
    if colors:
        body["controls"] = {"colors": colors}

    return body


def generate_image(
    prompt,
    output_path,
    model="recraftv2",
    style=None,
    substyle=None,
    colors=None,
    size="1024x1024",
    response_format="url",
    negative_prompt=None,
):
    """Recraft AI APIで画像を生成する"""
    token = get_api_token()

    # ネガティブプロンプトがある場合はプロンプトに追加
    full_prompt = prompt
    if negative_prompt:
        full_prompt = f"{prompt}. Avoid: {negative_prompt}"

    # リクエストボディ構築
    body = build_request_body(full_prompt, model, style, substyle, colors, size, response_format)

    print(f"モデル: {model}")
    print(f"スタイル: {style or '(なし)'}")
    if substyle:
        print(f"サブスタイル: {substyle}")
    print(f"サイズ: {size}")
    print(f"プロンプト: {prompt[:100]}{'...' if len(prompt) > 100 else ''}")
    print()

    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.post(API_URL, headers=headers, json=body, timeout=120)
    except requests.exceptions.Timeout:
        print("エラー: APIリクエストがタイムアウトしました（120秒）")
        sys.exit(1)
    except requests.exceptions.ConnectionError:
        print("エラー: APIサーバーに接続できません。ネットワーク接続を確認してください。")
        sys.exit(1)

    # エラーハンドリング
    if response.status_code == 401:
        print("エラー: APIトークンが無効です。トークンを確認してください。")
        print("  取得先: https://app.recraft.ai/profile/api")
        sys.exit(1)
    elif response.status_code == 402:
        print("エラー: APIユニット残高が不足しています。")
        print("  https://app.recraft.ai/profile/api でクレジットを追加してください。")
        sys.exit(1)
    elif response.status_code == 429:
        print("エラー: レート制限に達しました。少し待ってから再試行してください。")
        sys.exit(1)
    elif response.status_code != 200:
        print(f"エラー: APIリクエストに失敗しました (HTTP {response.status_code})")
        try:
            error_detail = response.json()
            print(f"  詳細: {json.dumps(error_detail, ensure_ascii=False, indent=2)}")
        except Exception:
            print(f"  レスポンス: {response.text[:500]}")
        sys.exit(1)

    # レスポンス解析
    result = response.json()
    data = result.get("data", [])

    if not data:
        print("エラー: 画像が生成されませんでした。プロンプトを変えて再試行してください。")
        sys.exit(1)

    # 出力ディレクトリ作成
    os.makedirs(os.path.dirname(output_path) or ".", exist_ok=True)

    # ベクターモデルかどうか判定
    is_vector = "vector" in model

    # 出力パスの拡張子を調整
    if is_vector and not output_path.endswith(".svg"):
        base, _ = os.path.splitext(output_path)
        output_path = base + ".svg"
        print(f"ベクターモデルのため、出力形式をSVGに変更: {output_path}")

    image_data = data[0]

    if response_format == "b64_json" and "b64_json" in image_data:
        import base64

        decoded = base64.b64decode(image_data["b64_json"])
        with open(output_path, "wb") as f:
            f.write(decoded)
    elif "url" in image_data:
        image_url = image_data["url"]
        img_response = requests.get(image_url, timeout=60)
        if img_response.status_code != 200:
            print(f"エラー: 画像のダウンロードに失敗しました (HTTP {img_response.status_code})")
            sys.exit(1)
        with open(output_path, "wb") as f:
            f.write(img_response.content)
    else:
        print("エラー: レスポンスに画像データが含まれていません。")
        print(f"  レスポンス: {json.dumps(result, ensure_ascii=False, indent=2)[:500]}")
        sys.exit(1)

    print(f"画像を保存しました: {output_path}")
    file_size = os.path.getsize(output_path)
    print(f"ファイルサイズ: {file_size:,} bytes")


def main():
    parser = argparse.ArgumentParser(
        description="Recraft AI 画像生成スクリプト",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用例:
  # アイコン生成 (V2 + icon スタイル)
  python3 generate_recraft_image.py "coin icon, orange" "output.png" --model recraftv2 --style icon --substyle colored_outline --colors "255,107,53"

  # SVGベクターアイコン生成
  python3 generate_recraft_image.py "store building icon" "output.svg" --model recraftv2_vector --style icon --substyle outline --colors "255,107,53"

  # 高品質ロゴ (V4 Vector)
  python3 generate_recraft_image.py "modern logo for GrouMap" "logo.svg" --model recraftv4_vector --colors "255,107,53"

  # 複数色指定
  python3 generate_recraft_image.py "colorful icon" "output.png" --colors "255,107,53;251,246,242"

環境変数:
  RECRAFT_API_TOKEN  Recraft AI APIトークン (必須)
                     取得先: https://app.recraft.ai/profile/api
        """,
    )

    parser.add_argument("prompt", help="画像生成プロンプト (最大4000文字)")
    parser.add_argument("output_path", help="出力ファイルパス (.png or .svg)")
    parser.add_argument(
        "--model",
        default="recraftv2",
        help="モデル名 (default: recraftv2). 選択肢: recraftv2, recraftv2_vector, recraftv3, recraftv3_vector, recraftv4, recraftv4_vector",
    )
    parser.add_argument(
        "--style",
        default=None,
        help="スタイル (V2/V3のみ). 選択肢: icon, vector_illustration, digital_illustration, realistic_image",
    )
    parser.add_argument(
        "--substyle",
        default=None,
        help="サブスタイル (iconスタイル用). 選択肢: outline, colored_outline, colored_shape, doodle, pictogram, gradient_outline, gradient_shape, broken_line, offset_doodle, offset_fill",
    )
    parser.add_argument(
        "--colors",
        default=None,
        help='RGB カラー指定. 形式: "R,G,B" (単色) or "R,G,B;R,G,B" (複数色). 例: "255,107,53"',
    )
    parser.add_argument(
        "--size",
        default="1024x1024",
        help="画像サイズ (default: 1024x1024). 選択肢: square_hd, square, 1024x1024, 1280x1024, 1536x1024, etc.",
    )
    parser.add_argument(
        "--format",
        dest="response_format",
        default="url",
        choices=["url", "b64_json"],
        help="レスポンス形式 (default: url)",
    )
    parser.add_argument(
        "--negative-prompt",
        default=None,
        help="ネガティブプロンプト（避けたい要素）",
    )

    args = parser.parse_args()

    # バリデーション
    if args.model in MODELS_WITHOUT_STYLE and args.style:
        print(f"警告: {args.model} モデルはスタイル指定をサポートしていません。スタイルは無視されます。")
        args.style = None

    if args.style and args.style not in VALID_STYLES:
        print(f"警告: 不明なスタイル '{args.style}'. 有効なスタイル: {', '.join(sorted(VALID_STYLES))}")

    if args.substyle and args.substyle not in ICON_SUBSTYLES:
        print(f"警告: 不明なサブスタイル '{args.substyle}'. 有効なサブスタイル: {', '.join(sorted(ICON_SUBSTYLES))}")

    colors = parse_colors(args.colors)

    generate_image(
        prompt=args.prompt,
        output_path=args.output_path,
        model=args.model,
        style=args.style,
        substyle=args.substyle,
        colors=colors,
        size=args.size,
        response_format=args.response_format,
        negative_prompt=args.negative_prompt,
    )


if __name__ == "__main__":
    main()
