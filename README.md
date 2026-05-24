# HillSafe AI 🏔️

**A smart early warning system that detects landslide and flood risks in real time — and alerts you before disaster strikes.**

Built for the mountainous regions of Pakistan (Murree, Swat, Kohistan, Hunza, and more).

---

## What It Does

- 📍 **Detects your location** automatically using your phone's GPS.
- 🌧️ **Fetches live weather** (rainfall, temperature) for your area.
- 🤖 **Predicts risk** using a Machine Learning model trained on historical landslide data.
- 🚨 **Sends push notifications** to warn you when your area becomes high risk.
- 🗺️ **Shows a live risk map** so you can see which regions are safe or dangerous.
- ✅ **Mark yourself safe** so authorities know your status.
- 📊 **Authorities get a command center** with analytics, alerts, and incident reports.

---

## How Predictions Work

1. The app reads your **GPS coordinates**.
2. It fetches **live rainfall and weather data** for that exact location.
3. That data (rainfall, slope, soil type) is sent to the **AI model** on the backend.
4. The model returns a **risk score** (Low / Moderate / High).
5. If the risk is high, an **alert is automatically created** and a **push notification is sent** to all users in that region.

This entire cycle also runs automatically every **10 minutes** on the server, scanning all monitored regions even while you sleep.

---

## Monitored Regions

Murree · Swat · Abbottabad · Mansehra · Kohistan · Chitral · Gilgit · Hunza · Skardu · Neelum Valley

---

## Project Layout

```
HillSafe-Ai/
├── Backend/         → Django API server (deployed on Render)
├── Frontend App/    → Flutter Android app
├── Datasets/        → Training data for the ML model
└── Weights/         → Trained ML model files
```

---

## Live Links

| | |
|---|---|
| 🌐 API | https://hillsafe-ai.onrender.com/api/ |
| 🛠️ Admin Panel | https://hillsafe-ai.onrender.com/admin/ |
| 🗄️ Database | Neon PostgreSQL (cloud hosted) |

---

## Built With

- **Flutter** — Mobile app (Android)
- **Django** — Backend API
- **scikit-learn + TensorFlow** — Landslide risk ML model
- **Open-Meteo** — Free live weather data
- **Firebase** — Push notifications
- **Render + Neon** — Cloud hosting & database
