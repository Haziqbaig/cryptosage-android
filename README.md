# CryptoSage AI — Android 📱

AI-powered crypto market analysis app built with **Flutter**. The Android counterpart of the [CryptoSage AI web app](https://github.com/Haziqbaig/crypto-ai-assistant), with the same branding, indicator engine, and rule-based AI recommendations.

> Phase 1: fully client-side, no backend, no API keys. Data from **CoinGecko** and **Alternative.me** free APIs.

## 📸 Screenshots

_Coming soon — Dashboard · Watchlist · Coin Detail · Search · Settings_

## ✨ Features

- **Dashboard** — total market cap, 24h change, BTC dominance, Fear & Greed gauge, top gainers/losers, trending coins, 60s auto-refresh
- **Watchlist** — defaults: BTC, ETH, SOL, SUI, DOGE, LINK, XRP, ADA · add/remove via search · persisted locally · shows price, 24h/7d %, market cap, RSI, MACD status, and AI rating badge
- **Coin Detail** — fl_chart price chart (24H/7D/30D/90D), RSI(14), MACD(12,26,9), EMA 20/50/200, ATH/ATL, supply & volume stats, and an **AI recommendation card** (rating, confidence %, reasons, risk, target, stop loss)
- **Search** — CoinGecko search with one-tap watchlist add
- **Settings** — currency (USD/EUR/PKR), dark/light theme (dark default), refresh interval
- Pull-to-refresh, shimmer loading skeletons, error states with retry, stale-cache fallback for rate limits

## 🧠 AI Recommendation Engine

Pure-Dart rule-based scoring over 90 days of daily closes:

| Signal | Logic |
|---|---|
| RSI(14) | <30 oversold (+), >70 overbought (−) |
| MACD(12,26,9) | bullish/bearish crossovers & histogram |
| EMA 20/50/200 | trend alignment vs price |
| 7d momentum | strong up/down moves |
| Fear & Greed | contrarian tilt at extremes |

Score maps to **Strong Buy → Strong Sell** with confidence %, volatility-based risk level, and support/resistance-derived target & stop loss.

**Not financial advice — educational analysis only.**

## 🏗️ Architecture

Clean architecture with the repository pattern:

```
lib/
├── core/           # theme (glassmorphism, cyan/violet), formatters
├── data/           # ApiClient (dio + shared_preferences cache), CryptoRepository
├── domain/         # models, Indicators (RSI/MACD/EMA/S&R), RecommendationEngine
└── presentation/   # Provider state (Settings/Dashboard/Watchlist), screens, widgets
```

## 🔨 Build

**CI (recommended):** every push to `main` builds a release APK via GitHub Actions and attaches it to a **GitHub Release** (also available as a workflow artifact).

**Local:**

```bash
flutter pub get
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Requirements: Flutter stable, Android SDK, JDK 17. Package id `com.cryptosage.ai`, minSdk 23.

## ⚠️ Known limitations (Phase 1)

- CoinGecko free tier rate limits — mitigated with per-request caching and stale-cache fallback
- Release APK is debug-signed (fine for sideloading; re-sign for Play Store)
- EMA200 needs 200 daily candles; shown as N/A when history is shorter
