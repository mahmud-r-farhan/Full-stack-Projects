# 💧 LiquidSync Gallery

> **The Privacy-First, High-Performance Gallery with Seamless LAN Sharing**
> Your media. Your device. Your rules.

---

## ✨ Overview

**LiquidSync Gallery** is a Flutter-based Android gallery application built on the philosophy of *Digital Sovereignty* — your photos and videos stay on your device, always. It replaces cloud-dependent gallery apps with a blazing-fast local experience, augmented by a powerful Local Area Network (LAN) sharing engine that lets any device on your Wi-Fi network browse and download your media without an internet connection.

The UI is inspired by **Apple Photos UX** rendered through a **Liquid Crystal (Glassmorphism)** design language — dark, elegant, and immersive.

---

## 🏗️ Architecture at a Glance

```
lib/
├── core/
│   ├── constants/        → AppConstants (ports, sizes, pref keys)
│   └── theme/            → AppTheme, AppColors, LiquidThemeExtension
│
├── data/
│   ├── models/           → MediaAsset, MediaGroup, LanServerInfo, VaultState, AppSettings
│   └── repositories/     → MediaRepository (wraps photo_manager safely)
│
├── features/
│   ├── gallery/
│   │   ├── presentation/
│   │   │   ├── screens/  → GalleryScreen, MediaViewerScreen
│   │   │   └── widgets/  → MediaTile
│   │   └── providers/    → galleryProvider, albumsProvider, mediaFilterProvider
│   │
│   ├── sharing/
│   │   ├── services/     → LanShareService (shelf HTTP server)
│   │   ├── providers/    → lanShareProvider
│   │   └── presentation/
│   │       └── screens/  → SharingScreen
│   │
│   ├── vault/
│   │   ├── services/     → VaultService (local_auth + secure_storage)
│   │   ├── providers/    → vaultProvider
│   │   └── presentation/
│   │       └── screens/  → VaultScreen
│   │
│   ├── settings/
│   │   ├── providers/    → AppSettingsNotifier, sharedPrefsProvider
│   │   └── presentation/
│   │       └── screens/  → SettingsScreen
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       └── screens/  → OnboardingScreen (4-page walkthrough)
│   │
│   └── shell/            → ShellScreen (IndexedStack + GlassNavBar)
│
├── shared/
│   └── widgets/          → GlassContainer, GlassButton, GlassNavBar,
│                           GradientText, AnimatedGradientBackground, EmptyState
│
└── main.dart             → App entry, ProviderScope, DynamicColorBuilder, router
```

---

## 🌟 Features

### 📸 Gallery
| Feature | Detail |
|---|---|
| Paginated loading | `GridView.builder` + `photo_manager` paged API — no OOM |
| Isolate offloading | Thumbnail mapping via `compute()` — zero UI jank |
| Filter by type | All / Photos / Videos filter chips |
| Album switching | Bottom sheet album picker |
| Media viewer | Full-screen `PageView` with `InteractiveViewer` pinch-zoom |
| Pull to refresh | Standard `RefreshIndicator` |
| Shimmer loading | Animated placeholder skeleton while first batch loads |
| Scroll-to-top FAB | Appears after 300px scroll, animates in/out |

### 📡 LAN Share — *The Killer Feature*
| Feature | Detail |
|---|---|
| Embedded HTTP server | `shelf` + `shelf_router` — runs entirely on-device |
| Zero internet needed | Connects via local Wi-Fi only |
| Web UI auto-generated | Full HTML/JS gallery browsable from any browser |
| JSON API | `/api/albums`, `/api/assets/<id>`, `/api/thumb/<id>`, `/api/file/<id>` |
| QR Code | `qr_flutter` generates a scannable code for instant connection |
| Copy URL | One-tap clipboard copy of the server URL |
| Auto IP detection | `network_info_plus` fetches device Wi-Fi IP automatically |

### 🔒 Vault
| Feature | Detail |
|---|---|
| Biometric gate | `local_auth` — fingerprint, face ID, device PIN |
| Secure storage | Asset IDs persisted with `flutter_secure_storage` (AES-256 encrypted prefs) |
| Hidden grid | Private media displayed only when authenticated |
| Lock on demand | One-tap lock returns vault to locked state |
| Move back | Long-press tile → "Remove from Vault" context menu |

### ⚙️ Settings
| Feature | Detail |
|---|---|
| Dark / Light mode | Toggle with immediate app-wide effect |
| Performance mode | Disables backdrop blur and animations for low-end devices |
| Grid columns | 2 / 3 / 4 column picker with animated preview |
| Vault enable/disable | Toggle vault feature on/off |
| Crash reporting opt-in | Privacy-first analytics toggle (user consent required) |

### 🎨 Design System — Liquid Crystal
| Token | Value |
|---|---|
| Primary | `#6C63FF` — Electric Violet |
| Accent | `#00D9FF` — Cyan Glow |
| Warm Accent | `#FF6B9D` — Rose |
| Background | `#0A0A14` — Deep Space |
| Glass color | `rgba(255,255,255,0.15)` |
| Blur sigma | `20px` (disabled in performance mode) |
| Border radius | `20px` (cards), `28px` (nav bar) |
| Typography | **Outfit** from Google Fonts |
| Dynamic Color | Material You (Android 12+) via `dynamic_color` |

---

## 📦 Technology Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter` | SDK | Core framework |
| `flutter_riverpod` | ^2.6.1 | State management + DI |
| `photo_manager` | ^3.6.4 | Safe device media access |
| `shelf` + `shelf_router` | ^1.4.2 / ^2.0.0 | Embedded LAN HTTP server |
| `network_info_plus` | ^6.1.3 | Wi-Fi IP detection |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `mobile_scanner` | ^7.0.0 | QR code scanning |
| `local_auth` | ^2.3.0 | Biometric authentication |
| `flutter_secure_storage` | ^9.2.4 | Encrypted vault storage |
| `flutter_animate` | ^4.5.2 | Micro-animations |
| `dynamic_color` | ^1.7.0 | Material You support |
| `video_player` + `chewie` | ^2.9.3 / ^1.8.5 | Video playback |
| `google_fonts` | ^6.2.1 | Outfit typography |
| `shared_preferences` | ^2.3.5 | Settings persistence |
| `exif` | ^3.3.0 | EXIF metadata parsing |
| `intl` | ^0.19.0 | Date formatting |

---

## 🚀 Getting Started

### Prerequisites
- Flutter `3.38.5` or later
- Android SDK (minSdk **23**, targetSdk **35**)
- A physical Android device is recommended (photo_manager requires real media access)

### Setup

```bash
# Clone the project
git clone <repo-url>
cd liquidsync_gallery

# Install dependencies
flutter pub get

# Run on a connected Android device
flutter run
```

### Android Permissions (auto-configured in AndroidManifest.xml)
```xml
READ_MEDIA_IMAGES / READ_MEDIA_VIDEO   <!-- Android 13+ -->
READ_EXTERNAL_STORAGE                   <!-- Android 9–12 fallback -->
INTERNET + ACCESS_WIFI_STATE           <!-- LAN server -->
USE_BIOMETRIC + USE_FINGERPRINT        <!-- Vault -->
CAMERA                                 <!-- QR scanner -->
```

---

## 📱 App Flow

```
App Launch
    │
    ├── First Launch → OnboardingScreen (4-page permissions walkthrough)
    │       └── "Get Started" → saves onboarding flag → ShellScreen
    │
    └── Returning User → ShellScreen (IndexedStack)
            ├── [0] GalleryScreen    — Media grid + viewer
            ├── [1] SharingScreen    — LAN server toggle + QR Code
            ├── [2] VaultScreen      — Biometric gate + hidden media
            └── [3] SettingsScreen   — App preferences
```

---

## 🔐 Privacy & Security

- **Zero cloud dependency** — no data ever leaves the device via this app
- **LAN Share is local-only** — HTTP server binds to `0.0.0.0` on your local network, unreachable from the internet
- **Vault storage** — uses `flutter_secure_storage` with `encryptedSharedPreferences = true` on Android (AES-256)
- **No analytics by default** — crash reporting requires explicit opt-in
- **Minimal permissions** — only requests permissions contextually when features are used

---

## 🗺️ Roadmap

### v1.0 (Current)
- [x] Fast paginated gallery with glassmorphism UI
- [x] LAN Share embedded server with Web UI + JSON API
- [x] Biometric Vault with secure storage
- [x] Settings (dark mode, performance mode, grid layout)
- [x] 4-page onboarding
- [x] Material You dynamic color support

### v2.0 (Planned)
- [ ] On-device AI photo tagging (search by "dog", "sunset", "birthday")
- [ ] End-to-end encrypted Vault (AES-256 file encryption)
- [ ] Face clustering & person albums
- [ ] EXIF data viewer & editor
- [ ] Desktop apps (Windows, macOS) for full ecosystem sync
- [ ] Advanced LAN share (upload from browser → phone)

---

## 📄 License

MIT License — see `LICENSE` file for details.

---

*Built with 💧 by the LiquidSync team. No cloud. No compromise.*
