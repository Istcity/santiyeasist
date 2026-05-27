# TestFlight — Şantiye Asist

## Uygulama bilgisi

| Alan | Değer |
|------|--------|
| Görünen ad | Şantiye Asist |
| Bundle ID | `com.levkonut.santiye` |
| Sürüm | 1.0.0 (1) |

## Xcode ile yükleme (önerilen)

1. `LevKonutSantiyeAsistani.xcodeproj` açın
2. Target → **Signing & Capabilities** → Team: Apple hesabınız
3. **Product → Archive**
4. Organizer → **Distribute App** → **App Store Connect** → **Upload**

## Komut satırı

```bash
cd ~/Documents/LevKonutSantiyeAsistani

# Archive
xcodebuild -project LevKonutSantiyeAsistani.xcodeproj \
  -scheme LevKonutSantiyeAsistani \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/SantiyeAsistani.xcarchive \
  archive

# IPA + App Store Connect yükleme
xcodebuild -exportArchive \
  -archivePath build/SantiyeAsistani.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

App Store Connect’te yeni uygulama oluştururken **Bundle ID** `com.levkonut.santiye` ile eşleşmeli.

## İlk TestFlight öncesi kontrol listesi

- [ ] [App Store Connect](https://appstoreconnect.apple.com) → My Apps → + → iOS → ad: **Şantiye Asist**
- [ ] AdMob canlı birim ID’leri (`AdManagerService` içinde test ID’leri production ile değiştirin)
- [ ] Gizlilik politikası URL’si (konum + reklam için gerekli olabilir)
- [ ] Ekran görüntüleri (6.7" ve 6.5")
