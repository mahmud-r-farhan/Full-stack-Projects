# Lumina Gallery — Enhancement Task Plan

## Agent: Antigravity (Google DeepMind)
## Date: 2026-02-26
## Agenda: Pure Privacy (Digital Sovereignty) Focus

---

## 🎯 App Identity

- **Full Name**: Lumina Gallery: Photo & Share
- **Short Name**: Lumina Gallery
- **Description**: Lightning-fast gallery. Hide photos & share to PC/TV instantly via Wi-Fi!

---

## ✅ Task Checklist

### 1. Core Identity & Branding
- [x] Rename app from "LiquidSync Gallery" → "Lumina Gallery"
- [x] Update app description, constants, labels
- [x] Update AndroidManifest.xml label
- [x] Update onboarding text to reflect new branding

### 2. Permission & Onboarding Flow
- [x] First-time launch shows permission request for file/media access
- [x] User-friendly permission acceptance with clear privacy messaging
- [x] Onboarding integrates permission grant directly
- [x] Graceful fallback if permission is denied

### 3. Gallery Enhancements
- [x] Album thumbnail preview (cover photo for each album)
- [x] Support maximum image types (jpg, jpeg, png, raw, webp, heic, bmp, tiff, gif, svg)
- [x] Pinch-to-zoom gesture for grid column adjustment (2-6 columns)
- [x] Ultra-fast scrolling with thumbnail caching
- [x] Responsive design across phone/tablet

### 4. Video Player
- [x] In-app video player with controls 
- [x] Support mp4, mov, mkv, avi, webm, 3gp formats
- [x] Video thumbnail preview in gallery grid
- [x] Progress bar, play/pause, seek controls

### 5. Vault — Fix "Authentication Failed" Bug
- [x] Fix biometric authentication flow
- [x] Handle no-biometrics fallback (PIN/pattern)
- [x] Fix vault asset loading
- [x] Improve vault UI/UX with clear status feedback

### 6. LAN Share Enhancement
- [x] Professional web UI served to browsers
- [x] Album browse with thumbnail previews
- [x] Direct download support
- [x] Video streaming support
- [x] Connection status indicators
- [x] Pagination support in web UI
- [x] Proper MIME type detection for downloads

### 7. UI/UX Polish
- [x] Modern glassmorphism design maintained
- [x] Smooth animations and transitions
- [x] Responsive layouts
- [x] Dark mode default with Material You support
- [x] Image info/details panel (EXIF data)
- [x] Share/delete actions in media viewer

### 8. Performance
- [x] Isolate-based media loading
- [x] Lazy thumbnail loading
- [x] Pagination with infinite scroll
- [x] Performance mode toggle (reduce blur/animations)

---

## Architecture

```
lib/
├── core/
│   ├── constants/app_constants.dart
│   └── theme/app_theme.dart
├── data/
│   ├── models/models.dart
│   └── repositories/media_repository.dart
├── features/
│   ├── gallery/       — Media grid, viewer, album browser
│   ├── onboarding/    — Permission flow
│   ├── settings/      — App settings
│   ├── sharing/       — LAN server + web UI
│   ├── shell/         — Navigation shell
│   └── vault/         — Biometric-protected vault
├── shared/
│   └── widgets/       — Glass design system
└── main.dart
```
