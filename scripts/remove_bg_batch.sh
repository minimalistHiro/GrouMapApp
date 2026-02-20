#!/bin/bash
# remove.bg APIを使ってバッジ画像の背景を透過するバッチスクリプト
# Usage: ./remove_bg_batch.sh [処理枚数上限]

source ~/.zshrc 2>/dev/null

API_KEY="${REMOVE_BG_API_KEY}"
BADGE_DIR="/Users/kanekohiroki/Desktop/groumapapp/assets/images/badges"
LIMIT=${1:-50}
COUNT=0
SUCCESS=0
FAIL=0

if [ -z "$API_KEY" ]; then
    echo "ERROR: REMOVE_BG_API_KEY が設定されていません"
    exit 1
fi

echo "=== remove.bg バッジ背景透過バッチ処理 ==="
echo "処理上限: ${LIMIT}枚"
echo ""

for file in "$BADGE_DIR"/*.png; do
    if [ $COUNT -ge $LIMIT ]; then
        echo ""
        echo "=== 上限 ${LIMIT} 枚に達したため停止 ==="
        break
    fi

    filename=$(basename "$file")
    echo -n "[$((COUNT + 1))/${LIMIT}] ${filename} ... "

    # 一時ファイルに出力
    TEMP_FILE="${file}.tmp"

    HTTP_CODE=$(curl -s -w "%{http_code}" \
        -H "X-Api-Key: ${API_KEY}" \
        -F "image_file=@${file}" \
        -F "size=auto" \
        -o "$TEMP_FILE" \
        https://api.remove.bg/v1.0/removebg)

    if [ "$HTTP_CODE" = "200" ]; then
        # 成功したら元ファイルを上書き
        mv "$TEMP_FILE" "$file"
        echo "OK"
        SUCCESS=$((SUCCESS + 1))
    else
        # 失敗したら一時ファイル削除
        rm -f "$TEMP_FILE"
        echo "FAIL (HTTP ${HTTP_CODE})"
        FAIL=$((FAIL + 1))
    fi

    COUNT=$((COUNT + 1))

    # APIレート制限対策（0.5秒待機）
    sleep 0.5
done

echo ""
echo "=== 処理完了 ==="
echo "成功: ${SUCCESS}枚"
echo "失敗: ${FAIL}枚"
echo "合計: ${COUNT}枚"
