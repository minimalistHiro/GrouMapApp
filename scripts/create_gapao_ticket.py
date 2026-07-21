#!/usr/bin/env python3
"""ぐるまっぷのサービス終了に伴うガパオライス無料券を作成する。"""

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tmp" / "pdf_deps"))

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from reportlab.lib.colors import Color
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfgen import canvas


CUTOUT_PATH = ROOT / "generated_images" / "gapao_product_cutout.png"
ICON_PATH = ROOT / "assets" / "images" / "groumap_icon.png"
PNG_PATH = ROOT / "generated_images" / "cocoshiva_gapao_free_ticket.png"
PDF_PATH = ROOT / "output" / "pdf" / "cocoshiva_gapao_free_ticket_business_card.pdf"
A4_PDF_PATH = ROOT / "output" / "pdf" / "cocoshiva_gapao_free_ticket_a4_10up.pdf"

WIDTH = 1075
HEIGHT = 650
CARD_WIDTH_MM = 91
CARD_HEIGHT_MM = 55

FONT_REGULAR = "/System/Library/Fonts/ヒラギノ角ゴシック W4.ttc"
FONT_MEDIUM = "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc"
FONT_BOLD = "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc"

ORANGE = (244, 82, 20, 255)
DARK = (69, 42, 28, 255)
CREAM = (255, 248, 233, 255)
GREEN = (42, 95, 54, 255)


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size=size)


def prepare_icon(path: Path, target_height: int) -> Image.Image:
    """白背景を除き、アイコン本体だけを切り出す。"""
    icon = Image.open(path).convert("RGBA")
    white = Image.new("RGBA", icon.size, (255, 255, 255, 255))
    diff = ImageChops.difference(icon, white).convert("L")
    bbox = diff.point(lambda p: 255 if p > 10 else 0).getbbox()
    if bbox:
        icon = icon.crop(bbox)

    pixels = icon.load()
    for y in range(icon.height):
        for x in range(icon.width):
            r, g, b, _ = pixels[x, y]
            distance = max(255 - r, 255 - g, 255 - b)
            alpha = max(0, min(255, (distance - 4) * 10))
            pixels[x, y] = (r, g, b, alpha)

    target_width = round(icon.width * target_height / icon.height)
    return icon.resize((target_width, target_height), Image.Resampling.LANCZOS)


def prepare_product(path: Path, max_size: tuple[int, int]) -> Image.Image:
    """背景透過済みの商品を余白なしで切り出し、指定範囲へ収める。"""
    product = Image.open(path).convert("RGBA")
    bbox = product.getchannel("A").getbbox()
    if not bbox:
        raise ValueError("背景透過済みの商品画像に不透明部分がありません。")
    product = product.crop(bbox)
    scale = min(max_size[0] / product.width, max_size[1] / product.height)
    size = (max(1, round(product.width * scale)), max(1, round(product.height * scale)))
    return product.resize(size, Image.Resampling.LANCZOS)


def rounded_panel(size: tuple[int, int], radius: int, fill: tuple[int, int, int, int]) -> Image.Image:
    panel = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(panel)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=fill)
    return panel


def centered_text(draw: ImageDraw.ImageDraw, bounds: tuple[int, int, int, int], text: str,
                  text_font: ImageFont.FreeTypeFont, fill: tuple[int, int, int, int]) -> None:
    x1, y1, x2, y2 = bounds
    bbox = draw.textbbox((0, 0), text, font=text_font)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    x = x1 + (x2 - x1 - width) / 2
    y = y1 + (y2 - y1 - height) / 2 - bbox[1]
    draw.text((x, y), text, font=text_font, fill=fill)


def create_ticket() -> Image.Image:
    card = Image.new("RGBA", (WIDTH, HEIGHT), CREAM)
    draw = ImageDraw.Draw(card)

    # 実物商品の切り抜きが映える、温かみのあるシンプルな背景。
    draw.ellipse((525, 42, 1125, 642), fill=(255, 220, 189, 205))
    draw.ellipse((625, 108, 1087, 570), fill=(255, 235, 209, 230))

    product = prepare_product(CUTOUT_PATH, (530, 430))
    product_x = WIDTH - product.width - 25
    product_y = 129 + max(0, (430 - product.height) // 2)
    shadow = Image.new("RGBA", product.size, (0, 0, 0, 0))
    shadow.putalpha(product.getchannel("A").filter(ImageFilter.GaussianBlur(16)))
    shadow_color = Image.new("RGBA", product.size, (74, 43, 24, 95))
    shadow_color.putalpha(shadow.getchannel("A").point(lambda a: round(a * 0.35)))
    card.alpha_composite(shadow_color, (product_x + 13, product_y + 18))
    card.alpha_composite(product, (product_x, product_y))

    # 印刷時の断裁を意識した内側の二重罫線。
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle((13, 13, WIDTH - 14, HEIGHT - 14), radius=30, outline=(255, 255, 255, 220), width=8)
    draw.rounded_rectangle((23, 23, WIDTH - 24, HEIGHT - 24), radius=24, outline=(244, 82, 20, 205), width=4)

    icon = prepare_icon(ICON_PATH, 108)
    card.alpha_composite(icon, (54, 46))

    # 上部のブランド・終了メッセージ。
    draw = ImageDraw.Draw(card)
    draw.text((180, 58), "ぐるまっぷ サービス終了に伴い", font=font(FONT_MEDIUM, 27), fill=ORANGE)
    draw.text((180, 101), "これまでのご利用に、心より感謝を込めて。", font=font(FONT_REGULAR, 22), fill=DARK)

    # 右上に、ペンで日付を書き込める有効期限欄を確保する。
    expiry_shadow = rounded_panel((330, 74), 17, (76, 38, 24, 50)).filter(ImageFilter.GaussianBlur(5))
    card.alpha_composite(expiry_shadow, (707, 43))
    expiry = rounded_panel((330, 74), 17, (255, 255, 255, 242))
    card.alpha_composite(expiry, (700, 36))
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle((700, 36, 1029, 109), radius=17, outline=(244, 82, 20, 190), width=3)
    draw.text((718, 57), "有効期限", font=font(FONT_MEDIUM, 20), fill=ORANGE)
    draw.line((812, 87, 1006, 87), fill=(111, 82, 63, 255), width=2)

    # 主見出し。
    draw.text((58, 183), "ガパオライス", font=font(FONT_BOLD, 67), fill=DARK, stroke_width=1, stroke_fill=(255, 250, 239, 255))

    badge = rounded_panel((445, 143), 33, ORANGE)
    badge_shadow = rounded_panel((445, 143), 33, (76, 38, 24, 90)).filter(ImageFilter.GaussianBlur(7))
    card.alpha_composite(badge_shadow, (66, 288))
    card.alpha_composite(badge, (58, 278))
    draw = ImageDraw.Draw(card)
    draw.text((83, 296), "1杯", font=font(FONT_BOLD, 55), fill=(255, 255, 255, 255))
    draw.text((208, 285), "無料券", font=font(FONT_BOLD, 78), fill=(255, 255, 255, 255))

    # 利用案内と店舗名。
    info = rounded_panel((486, 128), 23, (255, 255, 255, 218))
    card.alpha_composite(info, (48, 467))
    draw = ImageDraw.Draw(card)
    draw.text((69, 485), "本券1枚でガパオライス1杯を無料でご提供します。", font=font(FONT_MEDIUM, 20), fill=DARK)
    draw.text((69, 521), "ご利用時に本券をスタッフへお渡しください。", font=font(FONT_REGULAR, 19), fill=DARK)
    draw.line((69, 558, 354, 558), fill=(236, 190, 165, 255), width=2)
    draw.text((69, 566), "Antenna Books & Cafe ココシバ", font=font(FONT_BOLD, 18), fill=GREEN)

    # 料理写真側に小さなラベルを添え、視線の流れを整える。
    label = rounded_panel((235, 57), 28, (42, 95, 54, 230))
    card.alpha_composite(label, (799, 554))
    draw = ImageDraw.Draw(card)
    centered_text(draw, (799, 554, 1034, 611), "THANK YOU", font(FONT_BOLD, 23), (255, 255, 255, 255))

    card = card.convert("RGB")
    PNG_PATH.parent.mkdir(parents=True, exist_ok=True)
    card.save(PNG_PATH, dpi=(300, 300), quality=95)
    return card


def create_single_pdf() -> None:
    PDF_PATH.parent.mkdir(parents=True, exist_ok=True)
    page_width = CARD_WIDTH_MM * mm
    page_height = CARD_HEIGHT_MM * mm
    pdf = canvas.Canvas(str(PDF_PATH), pagesize=(page_width, page_height), pageCompression=1)
    pdf.setTitle("Antenna Books & Cafe ココシバ ガパオライス無料券")
    pdf.setAuthor("Antenna Books & Cafe ココシバ")
    pdf.drawImage(str(PNG_PATH), 0, 0, width=page_width, height=page_height, preserveAspectRatio=True, mask="auto")
    pdf.showPage()
    pdf.save()


def draw_crop_marks(pdf: canvas.Canvas, left: float, bottom: float, width: float, height: float) -> None:
    mark = 3.5 * mm
    gap = 0.8 * mm
    pdf.setStrokeColor(Color(0.25, 0.25, 0.25, alpha=1))
    pdf.setLineWidth(0.25)
    corners = [
        (left, bottom),
        (left + width, bottom),
        (left, bottom + height),
        (left + width, bottom + height),
    ]
    for x, y in corners:
        x_dir = -1 if x == left else 1
        y_dir = -1 if y == bottom else 1
        pdf.line(x + x_dir * gap, y, x + x_dir * (gap + mark), y)
        pdf.line(x, y + y_dir * gap, x, y + y_dir * (gap + mark))


def create_a4_pdf() -> None:
    page_width, page_height = A4
    card_width = CARD_WIDTH_MM * mm
    card_height = CARD_HEIGHT_MM * mm
    grid_width = card_width * 2
    grid_height = card_height * 5
    origin_x = (page_width - grid_width) / 2
    origin_y = (page_height - grid_height) / 2

    pdf = canvas.Canvas(str(A4_PDF_PATH), pagesize=A4, pageCompression=1)
    pdf.setTitle("Antenna Books & Cafe ココシバ ガパオライス無料券 A4 10面")
    pdf.setAuthor("Antenna Books & Cafe ココシバ")
    for row in range(5):
        for col in range(2):
            left = origin_x + col * card_width
            bottom = origin_y + (4 - row) * card_height
            pdf.drawImage(str(PNG_PATH), left, bottom, width=card_width, height=card_height,
                          preserveAspectRatio=True, mask="auto")
            draw_crop_marks(pdf, left, bottom, card_width, card_height)
    pdf.showPage()
    pdf.save()


def main() -> None:
    create_ticket()
    create_single_pdf()
    create_a4_pdf()
    print(PNG_PATH)
    print(PDF_PATH)
    print(A4_PDF_PATH)


if __name__ == "__main__":
    main()
