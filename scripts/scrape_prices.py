#!/usr/bin/env python3
"""
Merkezi malzeme fiyat scraper — GitHub Actions ile günde 4 kez çalıştırılır.
Kaynak: insaatdemiri.net (demir), proemtia.com (beton, seramik, çimento, bims, ytong, alçı, kum).
Çıktı: data/material_prices.json + uygulama bundle kopyası.
"""

from __future__ import annotations

import json
import re
import statistics
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
OUT_DATA = ROOT / "data" / "material_prices.json"
OUT_BUNDLE = ROOT / "LevKonutSantiyeAsistani" / "Resources" / "material_prices.json"

USER_AGENT = "SantiyeAsistPriceBot/1.0 (+https://github.com/Istcity/santiyeasist)"
TIMEOUT = 30
CARD_PARENT_DEPTH = 3
PROEMTIA_SOURCE = "proemtia.com"

PROEMTIA_CATEGORIES = {
    "seramik": "https://www.proemtia.com/urunler/seramik-karolari",
    "cimento": "https://www.proemtia.com/urunler/cimentolar",
    "bims": "https://www.proemtia.com/urunler/bimsler",
    "gazbeton": "https://www.proemtia.com/urunler/gazbetonlar",
    "alci": "https://www.proemtia.com/urunler/alcilar",
    "kum": "https://www.proemtia.com/urunler/kumlar",
}

SKIP_TITLES = frozenset({"Kategori", "Filtrele", "Boyut", "Lokasyon", "Kalite", ""})

# Uygulama şehir anahtarları → insaatdemiri.net etiketleri
CITY_DEMIR_LABELS: dict[str, str] = {
    "istanbul": "İstanbul (Avrupa)",
    "ankara": "Ankara",
    "izmir": "İzmir",
    "bursa": "Bursa",
    "canakkale_biga": "Çanakkale Biga",
}

CITY_BETON_MULTIPLIERS: dict[str, float] = {
    "istanbul": 1.08,
    "ankara": 1.05,
    "izmir": 1.06,
    "bursa": 1.04,
    "canakkale_biga": 1.0,
}


@dataclass
class ProductQuote:
    title: str
    price_try: float
    unit: str


def parse_tr_price(text: str) -> float | None:
    match = re.search(r"([\d\.]+,\d{2})", text.replace(" ", ""))
    if not match:
        return None
    raw = match.group(1).replace(".", "").replace(",", ".")
    try:
        return float(raw)
    except ValueError:
        return None


def parse_m2_from_title(title: str) -> float | None:
    match = re.search(r"(\d+[,\.]?\d*)\s*m\s*2", title, flags=re.IGNORECASE)
    if not match:
        return None
    try:
        return float(match.group(1).replace(",", "."))
    except ValueError:
        return None


def extract_card_price(text: str) -> tuple[float | None, str | None]:
    match = re.search(
        r"([\d\.]+,\d{2})\s*₺/(Adet|Ton|m²|m2|Metre|Torba|Kutu)",
        text,
        flags=re.IGNORECASE,
    )
    if not match:
        return None, None
    price = parse_tr_price(match.group(0))
    unit = match.group(2).lower().replace("²", "2")
    return price, unit


def fetch_proemtia_products(url: str) -> list[ProductQuote]:
    try:
        resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"Proemtia category failed {url}: {exc}", file=sys.stderr)
        return []

    soup = BeautifulSoup(resp.text, "html.parser")
    products: list[ProductQuote] = []

    for heading in soup.find_all("h5"):
        title = heading.get_text(" ", strip=True)
        if title in SKIP_TITLES or len(title) < 8:
            continue

        block = heading
        for _ in range(CARD_PARENT_DEPTH):
            if block.parent:
                block = block.parent

        text = block.get_text(" ", strip=True)
        price, unit = extract_card_price(text)
        if price is None or unit is None:
            continue

        products.append(ProductQuote(title=title, price_try=price, unit=unit))

    return products


def median(values: list[float]) -> float | None:
    if not values:
        return None
    return float(statistics.median(values))


def append_extended(
    items: list[dict[str, Any]],
    material_id: str,
    price: float | None,
    source: str,
) -> None:
    if price is None or price <= 0:
        return
    items.append(
        {
            "id": material_id,
            "priceTry": round(price, 2),
            "source": source,
        }
    )


def scrape_proemtia_extended() -> list[dict[str, Any]]:
    extended: list[dict[str, Any]] = []

    seramik_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["seramik"])
    yer_m2: list[float] = []
    duvar_m2: list[float] = []
    for product in seramik_products:
        area = parse_m2_from_title(product.title)
        if not area or area <= 0:
            continue
        per_m2 = product.price_try / area
        title_lower = product.title.lower()
        if "yer" in title_lower:
            yer_m2.append(per_m2)
        if "duvar" in title_lower:
            duvar_m2.append(per_m2)

    seramik_price = median(yer_m2) or median(duvar_m2)
    append_extended(extended, "seramik", seramik_price, PROEMTIA_SOURCE)

    # Proemtia'da cam kategorisi yok; duvar karosu m² referans fiyatı
    cam_price = median(duvar_m2) or median(yer_m2)
    append_extended(
        extended,
        "cam",
        cam_price,
        f"{PROEMTIA_SOURCE} (duvar karo ref.)",
    )

    cimento_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["cimento"])
    cimento_50 = [
        p.price_try
        for p in cimento_products
        if "50" in p.title and "kg" in p.title.lower()
    ]
    cimento_25 = [
        p.price_try * 2
        for p in cimento_products
        if "25" in p.title and "kg" in p.title.lower()
    ]
    cimento_price = median(cimento_50) or median(cimento_25) or median(
        [p.price_try for p in cimento_products]
    )
    append_extended(extended, "cimento", cimento_price, PROEMTIA_SOURCE)

    bims_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["bims"])
    gecmeli = [
        p.price_try
        for p in bims_products
        if "geçmeli" in p.title.lower() or "gecmeli" in p.title.lower()
    ]
    tugla_price = median(gecmeli) or median([p.price_try for p in bims_products if p.price_try < 20])
    append_extended(extended, "tugla", tugla_price, PROEMTIA_SOURCE)

    gazbeton_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["gazbeton"])
    block_prices = [
        p.price_try
        for p in gazbeton_products
        if p.price_try < 500 and "palet" not in p.title.lower()
    ]
    ytong_price = median(block_prices) or median(
        [p.price_try for p in gazbeton_products if p.price_try < 500]
    )
    append_extended(extended, "ytong", ytong_price, PROEMTIA_SOURCE)

    alci_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["alci"])
    alci_prices = [p.price_try for p in alci_products if p.price_try > 0]
    append_extended(extended, "alci", median(alci_prices), PROEMTIA_SOURCE)

    kum_products = fetch_proemtia_products(PROEMTIA_CATEGORIES["kum"])
    kaba = [
        p.price_try
        for p in kum_products
        if "kaba" in p.title.lower() or "şap" in p.title.lower() or "sap" in p.title.lower()
    ]
    kum_price = median(kaba) or median([p.price_try for p in kum_products])
    append_extended(extended, "kum", kum_price, PROEMTIA_SOURCE)

    return extended


def fetch_demir_by_city() -> dict[str, float]:
    url = "https://www.insaatdemiri.net/"
    resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=TIMEOUT)
    resp.raise_for_status()
    html = resp.text

    pattern = re.compile(
        r'<td class="column-1"><a[^>]*>([^<]+)</a></td>'
        r'<td class="column-2">[^<]+</td>'
        r'<td class="column-3">([0-9\.]+)\s*₺'
    )
    rows: dict[str, float] = {}
    for city, price_str in pattern.findall(html):
        price = float(price_str.replace(".", ""))
        rows[city.strip()] = price
    return rows


def fetch_proemtia_beton_reference() -> tuple[float | None, str]:
    url = "https://www.proemtia.com/urunler/hazir-betonlar"
    try:
        resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=TIMEOUT)
        resp.raise_for_status()
    except requests.RequestException as exc:
        print(f"Proemtia fetch failed: {exc}", file=sys.stderr)
        return None, "fallback"

    soup = BeautifulSoup(resp.text, "html.parser")
    text = soup.get_text(" ", strip=True)

    # KDV dahil m³ fiyatı: "3.600,00 ₺/Adet" — 1 adet = 1 m³
    prices: list[float] = []
    for match in re.finditer(r"([\d\.]+,\d{2})\s*₺/Adet", text):
        if "Hazır Beton" in text[max(0, match.start() - 120) : match.start()]:
            p = parse_tr_price(match.group(0))
            if p:
                prices.append(p)

    if not prices:
        # Genel regex yedek
        for match in re.finditer(r"([\d\.]+,\d{2})\s*₺/Adet", text):
            p = parse_tr_price(match.group(0))
            if p and 1500 < p < 15000:
                prices.append(p)

    if not prices:
        return None, "fallback"

    ref = min(prices)
    return ref, "proemtia.com"


def fetch_usd_try() -> float | None:
    try:
        resp = requests.get(
            "https://open.er-api.com/v6/latest/USD",
            headers={"User-Agent": USER_AGENT},
            timeout=TIMEOUT,
        )
        resp.raise_for_status()
        return float(resp.json()["rates"]["TRY"])
    except (requests.RequestException, KeyError, TypeError, ValueError) as exc:
        print(f"USD fetch failed: {exc}", file=sys.stderr)
        return None


def indexed_beton(usd_try: float, config_beton: float = 3500.0) -> float:
    reference_usd = 35.0
    reference_beton = 3720.74
    factor = usd_try / reference_usd
    indexed = reference_beton * (0.55 + 0.45 * factor)
    return (indexed * 0.65) + (config_beton * 0.35)


def build_feed() -> dict[str, Any]:
    demir_rows = fetch_demir_by_city()
    proemtia_beton, beton_source = fetch_proemtia_beton_reference()
    usd_try = fetch_usd_try() or 35.0

    if proemtia_beton is None:
        base_beton = indexed_beton(usd_try)
        beton_source = "İLBANK + USD endeksi"
    else:
        base_beton = proemtia_beton

    cities: list[dict[str, Any]] = []
    for city_key, demir_label in CITY_DEMIR_LABELS.items():
        demir_price = demir_rows.get(demir_label)
        if demir_price is None:
            # Kısmi eşleşme
            for label, price in demir_rows.items():
                if demir_label.split()[0].lower() in label.lower():
                    demir_price = price
                    demir_label = label
                    break

        if demir_price is None:
            demir_price = 33000 * (usd_try / 35.0)
            demir_source = "USD endeksi"
        else:
            demir_source = "insaatdemiri.net"

        multiplier = CITY_BETON_MULTIPLIERS.get(city_key, 1.0)
        beton_price = round(base_beton * multiplier, 2)

        cities.append(
            {
                "cityKey": city_key,
                "cityLabel": demir_label if demir_price else city_key,
                "betonC30": {
                    "priceTry": beton_price,
                    "unit": "m3",
                    "source": beton_source,
                },
                "rebar": {
                    "priceTry": round(demir_price, 2),
                    "unit": "ton",
                    "source": demir_source,
                },
            }
        )

    # Proemtia kategorilerinden genişletilmiş malzemeler
    extended = scrape_proemtia_extended()
    if not extended:
        extended = [
            {"id": "cimento", "priceTry": round(210 * (usd_try / 35.0), 2), "source": "USD endeksi"},
            {"id": "seramik", "priceTry": round(350 * (usd_try / 35.0), 2), "source": "USD endeksi"},
            {"id": "cam", "priceTry": round(420 * (usd_try / 35.0), 2), "source": "USD endeksi"},
            {"id": "tugla", "priceTry": round(8.5 * (usd_try / 35.0), 2), "source": "USD endeksi"},
            {"id": "ytong", "priceTry": round(32 * (usd_try / 35.0), 2), "source": "USD endeksi"},
        ]

    return {
        "version": 2,
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "usdTry": round(usd_try, 4),
        "cities": cities,
        "extended": extended,
    }


def main() -> None:
    feed = build_feed()
    payload = json.dumps(feed, ensure_ascii=False, indent=2)

    OUT_DATA.parent.mkdir(parents=True, exist_ok=True)
    OUT_DATA.write_text(payload + "\n", encoding="utf-8")
    OUT_BUNDLE.parent.mkdir(parents=True, exist_ok=True)
    OUT_BUNDLE.write_text(payload + "\n", encoding="utf-8")

    print(f"Wrote {OUT_DATA}")
    print(f"Wrote {OUT_BUNDLE}")
    print(
        f"Cities: {len(feed['cities'])}, extended: {len(feed.get('extended') or [])}, "
        f"updatedAt: {feed['updatedAt']}"
    )


if __name__ == "__main__":
    main()
