#!/usr/bin/env python3
"""Şantiye Asist — App Store 3D mockup ekran görüntüleri (tüm cihaz boyutları)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = Path(
    "/Users/sinannergiz/.cursor/projects/Users-sinannergiz-Documents-LevKonutSantiyeAsistani/assets"
)
OUTPUT = Path.home() / "Downloads" / "şantiye asist ekran görüntüsü"

NAVY = (26, 39, 68)
GOLD = (212, 168, 67)
CREAM = (245, 240, 232)
WHITE = (255, 255, 255)
BEZEL = (18, 22, 30)

FONT_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_REG = "/System/Library/Fonts/Supplemental/Arial.ttf"

# Apple App Store Connect — resmi boyutlar (portrait)
# https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications
SIZES: dict[str, tuple[int, int]] = {
    "6.9_inch": (1320, 2868),      # iPhone 16/17 Pro Max, 15 Pro Max…
    "6.5_inch": (1284, 2778),      # 6.5" (13 Pro Max, 11 Pro Max…)
    "6.3_inch": (1206, 2622),      # iPhone 16/17 Pro, 15 Pro…
    "5.5_inch": (1242, 2208),      # iPhone 8 Plus…
    "13_inch_iPad": (2064, 2752),  # iPad Pro 13"
}

SCREENS = [
    {
        "src": ASSETS
        / "WhatsApp_Image_2026-05-27_at_11.33.11__2_-cea67f2b-dcbf-4cf2-8935-6aa8bae82102.png",
        "slug": "01_dashboard",
        "headline": "Canlı Döviz &\nMalzeme Fiyatları",
        "subheadline": "Beton, demir ve şehir bazlı güncel fiyatlar",
        "remove_ad_strip": True,
    },
    {
        "src": ASSETS
        / "WhatsApp_Image_2026-05-27_at_11.33.11__1_-110d96d7-e301-4507-9508-f6234f5171d0.png",
        "slug": "02_yeni_proje",
        "headline": "Projelerinizi\nKolayca Yönetin",
        "subheadline": "Konut, ticari, endüstriyel ve villa projeleri",
        "remove_ad_strip": False,
    },
    {
        "src": ASSETS
        / "WhatsApp_Image_2026-05-27_at_11.33.11-74355d2a-98a7-46af-9bfc-37977b8fc56e.png",
        "slug": "03_ayarlar",
        "headline": "Bildirimler &\nFiyat Alarmları",
        "subheadline": "Sabah özeti, alarm ve premium özellikler",
        "remove_ad_strip": False,
    },
]


def load_font(path: str, size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def crop_status_bar(img: Image.Image, top_ratio: float = 0.054) -> Image.Image:
    w, h = img.size
    top = max(1, int(h * top_ratio))
    return img.crop((0, top, w, h))


def remove_ad_banner(img: Image.Image) -> Image.Image:
    """Dashboard'daki test reklam şeritlerini kaldır."""
    w, h = img.size
    # Kaynak ekran oranları (969px yükseklik referansı)
    cuts = [
        (int(h * 0.418), int(h * 0.518)),  # döviz altı reklam şeridi
        (int(h * 0.872), int(h * 0.924)),  # alt navigasyon üstü reklam
    ]
    segments: list[Image.Image] = []
    cursor = 0
    for start, end in sorted(cuts):
        if start > cursor:
            segments.append(img.crop((0, cursor, w, start)))
        cursor = end
    if cursor < h:
        segments.append(img.crop((0, cursor, w, h)))

    combined_h = sum(seg.height for seg in segments)
    out = Image.new("RGB", (w, combined_h), CREAM)
    y = 0
    for seg in segments:
        out.paste(seg, (0, y))
        y += seg.height
    return out


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def make_phone_mockup(screen: Image.Image, phone_h: int) -> Image.Image:
    bezel_x = int(phone_h * 0.045)
    bezel_top = int(phone_h * 0.018)
    bezel_bottom = int(phone_h * 0.022)
    corner = int(phone_h * 0.055)

    screen_h = phone_h - bezel_top - bezel_bottom
    screen_w = int(screen.size[0] * (screen_h / screen.size[1]))
    screen_resized = screen.resize((screen_w, screen_h), Image.Resampling.LANCZOS)

    phone_w = screen_w + bezel_x * 2
    phone = Image.new("RGBA", (phone_w, phone_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(phone)

    body_rect = (0, 0, phone_w - 1, phone_h - 1)
    draw.rounded_rectangle(body_rect, radius=corner, fill=(*BEZEL, 255))

    screen_mask = rounded_mask((screen_w, screen_h), max(8, corner - bezel_x // 2))
    screen_rgba = screen_resized.convert("RGBA")
    screen_rgba.putalpha(screen_mask)
    phone.paste(screen_rgba, (bezel_x, bezel_top), screen_rgba)

    notch_w = int(phone_w * 0.34)
    notch_h = int(phone_h * 0.028)
    notch_x = (phone_w - notch_w) // 2
    draw.rounded_rectangle(
        (notch_x, bezel_top - 2, notch_x + notch_w, bezel_top + notch_h),
        radius=notch_h // 2,
        fill=(8, 8, 10),
    )

    return phone


def add_shadow(layer: Image.Image, offset: tuple[int, int] = (0, 0), blur: int = 40) -> Image.Image:
    alpha = layer.split()[3]
    shadow = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    shadow.putalpha(alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    dark = Image.new("RGBA", layer.size, (0, 0, 0, 120))
    dark.putalpha(shadow.split()[3])
    canvas = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    canvas.alpha_composite(dark, offset)
    canvas.alpha_composite(layer, (0, 0))
    return canvas


def perspective_tilt(phone: Image.Image, direction: int = 1) -> Image.Image:
    """3D hissi: hafif eğim + perspektif ölçek."""
    angle = -7 * direction
    tilted = phone.rotate(angle, expand=True, resample=Image.Resampling.BICUBIC, fillcolor=(0, 0, 0, 0))
    w, h = tilted.size
    scale_bottom = 1.04
    scale_top = 0.96
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    strips = 24
    strip_h = max(1, h // strips)
    for i in range(strips):
        y0 = i * strip_h
        y1 = h if i == strips - 1 else (i + 1) * strip_h
        t = i / max(strips - 1, 1)
        scale = scale_top + (scale_bottom - scale_top) * t
        strip = tilted.crop((0, y0, w, y1))
        new_w = max(1, int(strip.width * scale))
        strip = strip.resize((new_w, strip.height), Image.Resampling.LANCZOS)
        x_off = (w - new_w) // 2 + int(direction * w * 0.012 * (1 - t))
        out.paste(strip, (x_off, y0))
    return out


def gradient_background(size: tuple[int, int], variant: int) -> Image.Image:
    w, h = size
    img = Image.new("RGB", size, NAVY)
    draw = ImageDraw.Draw(img)

    for y in range(h):
        t = y / max(h - 1, 1)
        if variant == 0:
            r = int(NAVY[0] * (1 - t) + 38 * t)
            g = int(NAVY[1] * (1 - t) + 58 * t)
            b = int(NAVY[2] * (1 - t) + 96 * t)
        elif variant == 1:
            r = int(34 * (1 - t) + CREAM[0] * t)
            g = int(48 * (1 - t) + CREAM[1] * t)
            b = int(78 * (1 - t) + CREAM[2] * t)
        else:
            r = int(NAVY[0] * (1 - t) + GOLD[0] * t * 0.35 + CREAM[0] * t * 0.65)
            g = int(NAVY[1] * (1 - t) + GOLD[1] * t * 0.35 + CREAM[1] * t * 0.65)
            b = int(NAVY[2] * (1 - t) + GOLD[2] * t * 0.35 + CREAM[2] * t * 0.65)
        draw.line([(0, y), (w, y)], fill=(r, g, b))

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    odraw = ImageDraw.Draw(overlay)
    for i in range(3):
        cx = int(w * (0.15 + i * 0.28))
        cy = int(h * (0.55 + (i % 2) * 0.1))
        radius = int(min(w, h) * 0.22)
        odraw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(212, 168, 67, 18 + i * 6),
        )
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")


def draw_headline(canvas: Image.Image, headline: str, subheadline: str, is_ipad: bool) -> None:
    draw = ImageDraw.Draw(canvas)
    w, h = canvas.size
    title_size = int(w * (0.078 if is_ipad else 0.095))
    sub_size = int(w * (0.034 if is_ipad else 0.042))
    title_font = load_font(FONT_BOLD, title_size)
    sub_font = load_font(FONT_REG, sub_size)

    x = int(w * 0.08)
    y = int(h * 0.07)

    for dx, dy, alpha in [(3, 3, 60), (0, 0, 255)]:
        draw.multiline_text(
            (x + dx, y + dy),
            headline,
            font=title_font,
            fill=(0, 0, 0, alpha) if alpha < 200 else WHITE,
            spacing=8,
        )

    draw.multiline_text((x, y), headline, font=title_font, fill=WHITE, spacing=8)
    sub_y = y + title_size * 2.2 + 10
    draw.text((x, sub_y), subheadline, font=sub_font, fill=(230, 225, 215))


def draw_logo_badge(canvas: Image.Image) -> None:
    draw = ImageDraw.Draw(canvas)
    w, _ = canvas.size
    size = int(w * 0.055)
    x = int(w * 0.08)
    y = int(canvas.size[1] * 0.045)
    draw.rounded_rectangle((x, y, x + size, y + size), radius=size // 5, fill=GOLD)
    bar_w = size // 5
    base = y + size - size // 4
    for i, ht in enumerate([size // 3, size // 2, size // 2.5]):
        bx = x + size // 4 + i * (bar_w + 2)
        draw.rectangle((bx, base - ht, bx + bar_w, base), fill=NAVY)


def compose_screenshot(
    screen: Image.Image,
    canvas_size: tuple[int, int],
    headline: str,
    subheadline: str,
    variant: int,
    screen_index: int,
) -> Image.Image:
    w, h = canvas_size
    is_ipad = w > 1600
    bg = gradient_background(canvas_size, variant)
    draw_logo_badge(bg)
    draw_headline(bg, headline, subheadline, is_ipad)

    phone_h = int(h * (0.62 if not is_ipad else 0.58))
    phone = make_phone_mockup(screen, phone_h)
    phone = perspective_tilt(phone, direction=1 if screen_index % 2 == 0 else -1)

    shadow_layer = add_shadow(phone, offset=(int(w * 0.012), int(h * 0.018)), blur=int(w * 0.025))

    px = int(w * (0.08 if screen_index % 2 == 0 else 0.18))
    py = int(h * (0.30 if not is_ipad else 0.28))
    if is_ipad:
        px = (w - shadow_layer.width) // 2
        py = int(h * 0.32)

    bg_rgba = bg.convert("RGBA")
    bg_rgba.alpha_composite(shadow_layer, (px, py))

    accent = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    ad = ImageDraw.Draw(accent)
    bubble_x = int(w * 0.62)
    bubble_y = int(h * 0.72)
    bubble_r = int(w * 0.09)
    ad.ellipse(
        (bubble_x - bubble_r, bubble_y - bubble_r, bubble_x + bubble_r, bubble_y + bubble_r),
        fill=(212, 168, 67, 45),
    )
    bg_rgba = Image.alpha_composite(bg_rgba, accent)

    return bg_rgba.convert("RGB")


def prepare_screen(meta: dict) -> Image.Image:
    img = Image.open(meta["src"]).convert("RGB")
    img = crop_status_bar(img)
    if meta.get("remove_ad_strip"):
        img = remove_ad_banner(img)
    return img


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    prepared = [prepare_screen(m) for m in SCREENS]

    for size_name, canvas_size in SIZES.items():
        folder = OUTPUT / size_name
        folder.mkdir(parents=True, exist_ok=True)
        for idx, (meta, screen) in enumerate(zip(SCREENS, prepared)):
            composed = compose_screenshot(
                screen=screen,
                canvas_size=canvas_size,
                headline=meta["headline"],
                subheadline=meta["subheadline"],
                variant=idx,
                screen_index=idx,
            )
            out_path = folder / f"{meta['slug']}.png"
            composed.save(out_path, "PNG", optimize=True)
            print(f"✓ {size_name}/{out_path.name} ({composed.size[0]}×{composed.size[1]})")

    readme = OUTPUT / "README.txt"
    readme.write_text(
        "Şantiye Asist — App Store ekran görüntüleri\n\n"
        "App Store Connect yükleme eşlemesi:\n"
        "  6.9_inch/     → 6.9\" Display slot (1320×2868) ★ ANA\n"
        "  6.5_inch/     → 6.5\" Display slot (1284×2778)\n"
        "  6.3_inch/     → 6.3\" Display slot (1206×2622)\n"
        "  5.5_inch/     → 5.5\" Display slot (1242×2208)\n"
        "  13_inch_iPad/ → 13\" Display slot (2064×2752)\n\n"
        "Her klasörde 3 ekran:\n"
        "  01_dashboard — Canlı döviz & malzeme fiyatları\n"
        "  02_yeni_proje — Proje oluşturma\n"
        "  03_ayarlar — Bildirimler & alarmlar\n\n"
        "Not: 1320×2868 = 6.9\" (6.3\" DEĞİL). 6.9 yüklediyseniz 6.5 zorunlu değil.\n",
        encoding="utf-8",
    )
    print(f"\nTamamlandı → {OUTPUT}")


if __name__ == "__main__":
    main()
