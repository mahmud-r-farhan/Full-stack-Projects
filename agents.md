# 📱 Project Overview: LiquidSync Gallery
**Target Platform:** Android (Primary), Web (Secondary/Client Access)
**Tech Stack:** Flutter, Dart
**Design Language:** Liquid Crystal (Glassmorphism) + Apple Photos inspired UX
**Core Philosophy:** Digital Sovereignty, Ultimate Performance, Seamless Local Network Sharing.

## 🧠 1. Core Idea & Psychological Approach
In 2026, users are experiencing "Cloud Fatigue." With the rise of AI data scraping and increasing subscription costs, users crave **Digital Sovereignty**—absolute control over their private media without sacrificing the convenience of ecosystem connectivity. 

**The Psychological Hook:** Give users the aesthetic pleasure of an Apple ecosystem (Liquid Crystal UI) combined with the ultimate freedom of Android. The app must feel like a "Sanctuary." Zero loading screens, zero cloud anxiety. The magic moment is the **LAN Sharing**: breaking the barrier between devices effortlessly via a local network, giving a "cloud-like" experience without the cloud.

## 📊 2. Market Analysis & Cap (2026 Perspective)
* **The 2026 Landscape:** The global personal cloud and local storage utility market is heavily pivoting towards hybrid or local-first solutions. Privacy-centric apps have seen a 300% adoption increase since 2024.
* **Target Audience:** Power users, photographers, privacy advocates, and everyday users frustrated with default OEM galleries (which are often bloated with ads or cloud prompts).
* **Market Positioning:** Positioned as a "Premium Utility." While the base is free, the seamless cross-device LAN sharing and Vault act as high-retention features, opening doors for a one-time premium unlock (freemium model), capturing a solid niche in the multi-million dollar mobile utility market.

## ⚙️ 3. Architecture & Technical Requirements

### 3.1 Core Engine (Media Access & Rendering)
* **Package:** `photo_manager` (Crucial: Do not use direct file system traversal for media).
* **Permissions (Android 13+):** `permission_handler` -> `READ_MEDIA_IMAGES` & `READ_MEDIA_VIDEO`.
* **Memory Management:** Implement heavy pagination (80-100 items per batch). Use `GridView.builder` strictly. Use `AssetEntity.thumbnailData` for blazing-fast micro-renders.
* **Thread Blocking Prevention:** ALL heavy tasks (video thumbnail generation, caching, EXIF reading) MUST run on separate threads using `Isolate` or `compute()`.

### 3.2 Network Sharing (The Killer Feature)
* **Server:** Embedded lightweight HTTP server using `shelf` or `alfred`.
* **Mechanics:** * Host device starts server on local IP (e.g., `http://192.168.x.x:8080`).
    * Provides a clean, auto-generated Web UI (HTML/JS) for non-app clients (PC, Smart TV).
    * If the client device also has the app installed, handle App-to-App direct P2P connection via socket/HTTP API.
    * P2P Sync: Auto-sync specific albums between two devices on the same Wi-Fi in the background.
* **Frictionless Entry:** Integrate `qr_flutter`. Host shows QR, Client scans -> Instantly opens the shared gallery.

### 3.3 User Retention & Core Features
* **Secure Vault:** Hidden folder secured via `local_auth` (Biometrics/PIN). Files moved here are encrypted or hidden from MediaStore `.nomedia`.
* **Smart Organization:** Auto-grouping by Date, Location (EXIF parsing), and Media Type.
* **Integrated Player:** Use `video_player` or `chewie`. Implement "Hover to auto-play" (muted) while scrolling, akin to premium social feeds.

## 🎨 4. UI/UX Guidelines: "Liquid Crystal"
* **Aesthetic:** Inspired by Apple Photos but modernized. Use Glassmorphism heavily but efficiently.
* **Components:** `BackdropFilter` and `ImageFilter.blur` for semi-transparent cards, bottom nav, and top app bars. (Consider the `glassmorphism` package).
* **Dynamic Theming:** Integrate `dynamic_color` for Android 12+ Material You (Monet) support to blend with the user's wallpaper.
* **Animations:** Use `Hero` widgets for zero-jitter image expansion. Use `flutter_animate` for spring/bounce effects on interaction.
* **Accessibility & Performance Toggle:** Add a "Performance Mode" in settings to reduce/disable animations and blurs for lower-end devices. *Performance over aesthetics when forced.*

## 📖 5. User Guide & Flow
1.  **Onboarding:** Clean, minimal permission request. Explains *why* permissions are needed.
2.  **Home Screen (Timeline):** Fast-loading grid of all media. Bottom floating glassmorphism nav bar.
3.  **Sharing Flow:** Tap "LAN Share" -> Server starts -> QR code displays -> Client scans/enters IP -> Connected.
4.  **Vault Flow:** Long-press a secret UI element (or specific tab) -> Biometric prompt -> Access hidden media.

## 🛠 6. Maintainability & Code Structure
* **Architecture:** Use MVVM or Clean Architecture with Riverpod/Bloc for state management. Keep UI entirely decoupled from the Localhost server logic.
* **Error Handling:** Silent fallbacks for missing EXIF data or corrupted files. No hard crashes.
* **Analytics (Privacy-First):** Only track non-identifying crash logs (if user opts-in). 


## 🚀 7. Feature Upgrade Planning (Scope for v2.0+)

1. **In App Ads:** In future app should contain the ads, so now stay in context for ads option implement with the next update.

2.  **On-Device AI Categorization:** Implement TensorFlow Lite for local image tagging (e.g., searching for "Dog", "Beach") without sending data to the cloud.
3.  **Cross-Platform Desktop Apps:** Compile the Flutter app for Windows/macOS to create a seamless ecosystem natively.

---
**Agent Directive:** When building components for this project, always prioritize frame-rate (60/120fps) and memory safety. Read the UI/UX guidelines carefully before proposing widget structures.