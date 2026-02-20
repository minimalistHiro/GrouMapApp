"""rembgを使ってバッジ画像の背景を一括透過するスクリプト"""
import os
import sys
from rembg import remove

BADGE_DIR = "/Users/kanekohiroki/Desktop/groumapapp/assets/images/badges"

# 処理済み（remove.bgで処理済み50枚 + rembgで処理済み1枚）をスキップ
ALREADY_PROCESSED = {
    # remove.bgで処理済み（カテゴリ別来店バッジ50枚）
    "category_asian_ethnic_visit_1.png", "category_asian_ethnic_visit_2.png",
    "category_asian_ethnic_visit_3.png", "category_asian_ethnic_visit_4.png",
    "category_asian_ethnic_visit_5.png", "category_cafe_sweets_visit_1.png",
    "category_cafe_sweets_visit_2.png", "category_cafe_sweets_visit_3.png",
    "category_cafe_sweets_visit_4.png", "category_cafe_sweets_visit_5.png",
    "category_italian_meat_visit_1.png", "category_italian_meat_visit_2.png",
    "category_italian_meat_visit_3.png", "category_italian_meat_visit_4.png",
    "category_italian_meat_visit_5.png", "category_izakaya_bar_visit_1.png",
    "category_izakaya_bar_visit_2.png", "category_izakaya_bar_visit_3.png",
    "category_izakaya_bar_visit_4.png", "category_izakaya_bar_visit_5.png",
    "category_nabe_yakiniku_visit_1.png", "category_nabe_yakiniku_visit_2.png",
    "category_nabe_yakiniku_visit_3.png", "category_nabe_yakiniku_visit_4.png",
    "category_nabe_yakiniku_visit_5.png", "category_ramen_chinese_visit_1.png",
    "category_ramen_chinese_visit_2.png", "category_ramen_chinese_visit_3.png",
    "category_ramen_chinese_visit_4.png", "category_ramen_chinese_visit_5.png",
    "category_shokudo_other_visit_1.png", "category_shokudo_other_visit_2.png",
    "category_shokudo_other_visit_3.png", "category_shokudo_other_visit_4.png",
    "category_shokudo_other_visit_5.png", "category_washoku_visit_1.png",
    "category_washoku_visit_2.png", "category_washoku_visit_3.png",
    "category_washoku_visit_4.png", "category_washoku_visit_5.png",
    "category_western_french_visit_1.png", "category_western_french_visit_2.png",
    "category_western_french_visit_3.png", "category_western_french_visit_4.png",
    "category_western_french_visit_5.png", "category_yakitori_age_visit_1.png",
    "category_yakitori_age_visit_2.png", "category_yakitori_age_visit_3.png",
    "category_yakitori_age_visit_4.png", "category_yakitori_age_visit_5.png",
    # rembgで処理済み
    "comment_posted_1.png",
}

def main():
    files = sorted(f for f in os.listdir(BADGE_DIR) if f.endswith(".png") and f not in ALREADY_PROCESSED)
    total = len(files)
    print(f"=== rembg バッジ背景透過バッチ処理 ===")
    print(f"対象: {total}枚")
    print()

    success = 0
    fail = 0

    for i, filename in enumerate(files, 1):
        filepath = os.path.join(BADGE_DIR, filename)
        print(f"[{i}/{total}] {filename} ... ", end="", flush=True)
        try:
            with open(filepath, "rb") as f:
                input_data = f.read()
            output_data = remove(input_data)
            with open(filepath, "wb") as f:
                f.write(output_data)
            print("OK")
            success += 1
        except Exception as e:
            print(f"FAIL ({e})")
            fail += 1

    print()
    print(f"=== 処理完了 ===")
    print(f"成功: {success}枚")
    print(f"失敗: {fail}枚")
    print(f"合計: {total}枚")

if __name__ == "__main__":
    main()
