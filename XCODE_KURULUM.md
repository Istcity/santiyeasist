# Şantiye Asist — Xcode Kurulum

## 1. Yeni proje

1. Xcode → **File → New → Project** → **iOS App**
2. Product Name: `LevKonutSantiyeAsistani`
3. Interface: **SwiftUI** · Language: **Swift**
4. Kayıt: `Documents/LevKonutSantiyeAsistani` (veya alt klasör)

## 2. Dosyaları ekle

Finder’dan şu klasörü Xcode’a sürükleyin:

`LevKonutSantiyeAsistani/LevKonutSantiyeAsistani/`

- **Copy items if needed** ✓
- **Create groups** ✓
- Target işaretli ✓

**Önemli:** `Resources` klasöründeki JSON dosyaları için:
- `default_unit_prices.json`
- `default_inspection_fees.json`

Target → **Build Phases** → **Copy Bundle Resources** içinde göründüklerinden emin olun.

## 3. Swift Package Manager

| Paket | URL |
|--------|-----|
| Firebase | `https://github.com/firebase/firebase-ios-sdk` |
| Google Mobile Ads | `https://github.com/googleads/swift-package-manager-google-mobile-ads` |

Ürünler: **FirebaseCore**, **FirebaseRemoteConfig**

## 4. Firebase

- `GoogleService-Info.plist` → Xcode target’a ekleyin
- Console → Remote Config: `beton_m3_fiyat`, `demir_ton_fiyat`, `interstitial_ad_frequency`

## 5. Info.plist

| Anahtar | Değer |
|---------|--------|
| `GADApplicationIdentifier` | `ca-app-pub-8420759480841389~1653740471` |
| `NSLocationWhenInUseUsageDescription` | Şantiye konumuna göre hava durumu için konum kullanılır. |

## 6. Ekranlar

| Ekran | Dosya |
|--------|--------|
| Ana özet | `DashboardView.swift` |
| Maliyet | `CostCalculatorView.swift` |
| Yapı denetim | `InspectionView.swift` |

Tüm alt ekranlarda **üst + alt banner** (`ScreenWithAdsLayout`).

## 7. Çalıştır

Scheme **LevKonutSantiyeAsistani** → iPhone → **⌘R**
