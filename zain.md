# HillSafe AI — Deployment & Troubleshooting Guide

This guide provides step-by-step instructions on how to deploy the Django backend to Render, the required `.env` / environment variable configurations, and troubleshooting steps for the mobile app GPS location services.

---

## 1. Render Deployment Guide

To deploy the HillSafe AI Django backend web service to Render, configure your Web Service setup with the following parameters:

### Render Web Service Settings:
* **Repository**: Link your GitHub repository (`HillSafe-AI`)
* **Root Directory**: `Backend` (crucial, as the Django app is nested inside this folder)
* **Environment**: `Python`
* **Region**: Select the closest region to your users (e.g., Singapore or Europe)
* **Branch**: `Active` (or your merged tracking branch like `active-icon-updates`)

### Build & Start Commands:
* **Build Command**:
  ```bash
  pip install -r requirements.txt && python manage.py collectstatic --noinput && python manage.py migrate && python create_superuser.py && python seed_regions.py
  ```
  *(This automatically installs packages, generates static files, applies database migrations, seeds regions, and creates a default superuser on every deployment)*
* **Start Command**:
  ```bash
  gunicorn hillsafe_core.wsgi:application
  ```

---

## 2. Environment Variables (.env Configuration)

Render holds all secrets securely inside its dashboard. Do **NOT** commit your `.env` file to GitHub. Instead, add the following key-value pairs under the **"Environment Variables"** tab in your Render Web Service dashboard:

### Database Settings (Neon PostgreSQL):
* `DB_HOST` — The host address of your Neon database cluster (e.g., `ep-xxxx-xxxx.ap-southeast-1.aws.neon.tech`)
* `DB_NAME` — `hillsafe_db` (or your Neon database name)
* `DB_USER` — `postgres` (or your database username)
* `DB_PASSWORD` — Your secure database password
* `DB_PORT` — `5432`

### Django Core Settings:
* `SECRET_KEY` — A secure, random secret key (e.g., `django-insecure-...`)
* `DEBUG` — `False` (forces secure production constraints)
* `ALLOWED_HOSTS` — `*` or `hillsafe-ai.onrender.com`

### Live API Keys:
* `OPENWEATHER_API_KEY` — `<YOUR_OPENWEATHER_API_KEY>` (your active OpenWeatherMap API key)
* `WEATHER_API_KEY` — `<YOUR_OPENWEATHER_API_KEY>` (identical, kept for fallback compatibility)
* `GEMINI_API_KEY` — `<YOUR_GEMINI_API_KEY>` (your Gemini API key for the AI Chatbot Assistant)

---

## 3. Troubleshooting: "Location service is unavailable" on Android

If you launch the app on another phone and the Weather & Risk Widget displays **"Location services are disabled"** or **"Location service is unavailable"**, it is due to device-level settings. 

Follow these simple steps to resolve it:

### Step 1: Turn ON Device GPS (Location Switch)
The phone’s global hardware GPS switch is turned off.
1. Swipe down from the top of the phone screen to open the **Android Quick Settings Panel**.
2. Locate the **"Location"** or **"GPS"** icon (usually a map pin 📍).
3. Tap it to turn it **ON** (so it lights up/activates).

### Step 2: Grant App Permissions
The application needs permission to read the location coordinates.
1. Open the phone's **Settings** app.
2. Go to **Apps** (or *Apps & Notifications*) ➔ **HillSafe AI**.
3. Tap **Permissions** ➔ **Location**.
4. Select **"Allow only while using the app"** and ensure **"Use precise location"** is toggled ON.

### Step 3: Refresh the Widget
Once GPS is active and permissions are granted:
1. Return to the **HillSafe AI** app dashboard.
2. Tap the small circular **Reload/Refresh** icon (🔄) on the right side of the Weather & Risk card.
3. The card will instantly load the live weather forecast and run the ML prediction successfully!
