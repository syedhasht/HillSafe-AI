# HillSafe AI - Disaster Early Warning System

## Overview
HillSafe AI is a comprehensive disaster early warning system designed to monitor, predict, and alert authorities and communities about potential environmental hazards. The system integrates real-time data ingestion, machine learning-based risk prediction, and a mobile application for timely dissemination of critical information.

## Key Features
- **Real-time Monitoring**: Tracks weather conditions and environmental parameters.
- **Risk Prediction**: Utilizes Machine Learning models to predict disaster risks (e.g., landslides, floods).
- **Early Warning Alerts**: Sends push notifications to authorities and residents in affected regions.
- **Interactive Map**: Visualizes risk zones and safe locations using Flutter Map.
- **Report Management**: Allows users to report incidents and authorities to manage them.

## Tech Stack

### Backend
- **Framework**: Django (Python)
- **Database**: SQLite (Development) / PostgreSQL (Production ready)
- **ML Engine**: Custom ML models for risk assessment
- **API**: RESTful APIs for frontend communication

### Frontend (Mobile App)
- **Framework**: Flutter
- **State Management**: Provider
- **Maps**: flutter_map, latlong2
- **Notifications**: Firebase Messaging, flutter_local_notifications

## Project Structure
- `backend/`: Contains the Django project, including apps for alerts, predictions, regions, and data ingestion.
- `flutter_application_2/`: The Flutter mobile application source code.
- `Datasets/`: Datasets used for training ML models.

## Quick Start (If You Already Have the Project)

> **Note**: This project includes a pre-configured virtual environment (`venv`) in the `backend` folder. If you already have the project cloned, follow these quick steps:

### Option 1: Using Existing Virtual Environment (Fastest)

**Backend:**
```bash
cd backend
venv\Scripts\activate          # Windows
# OR
source venv/bin/activate       # macOS/Linux

# Install/update dependencies
pip install -r requirements.txt

# Run migrations and start server
python manage.py migrate
python manage.py runserver
```

**Frontend:**
```bash
cd flutter_application_2
flutter pub get
flutter run
```

### Option 2: Using Automated Setup Script (Windows Only)

```bash
cd backend
setup_django.bat
```

This script will automatically activate the venv and set up the Django apps.

---

## Getting Started on a New Device

### System Requirements

#### Backend Requirements
- **Python**: 3.8 or higher (3.12 recommended)
- **pip**: Latest version
- **PostgreSQL**: 12+ (optional, SQLite used by default for development)
- **Git**: For version control

#### Frontend Requirements
- **Flutter SDK**: 3.0 or higher
- **Dart SDK**: Included with Flutter
- **Android Studio** (for Android development) or **Xcode** (for iOS development on macOS)
- **VS Code** or **Android Studio** (IDE)
- **Android SDK**: API Level 21 or higher
- **Java JDK**: 11 or higher

---

## Backend Setup (Django)

### Step 1: Clone the Repository
```bash
git clone https://github.com/AliAzwar02/hillsafe-ai.git
cd hillsafe-ai
```

### Step 2: Navigate to Backend Directory
```bash
cd backend
```

### Step 3: Activate or Create Virtual Environment

> **Important**: This project already includes a `venv` folder. If you cloned the repository, you can use the existing virtual environment. If it's missing or corrupted, create a new one.

**Option A: Use Existing Virtual Environment (Recommended)**

**On Windows:**
```bash
venv\Scripts\activate
```

**On macOS/Linux:**
```bash
source venv/bin/activate
```

**Option B: Create New Virtual Environment (If needed)**

**On Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**On macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

> **Tip**: You'll know the virtual environment is activated when you see `(venv)` at the beginning of your command prompt.


### Step 4: Install Dependencies
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### Step 5: Configure Environment Variables

> **Note**: A `.env` file already exists in the `backend` directory with default configuration. You can use it as-is for development or customize it as needed.

The existing `.env` file contains:
```bash
# Django Settings
SECRET_KEY=your-secret-key-here-change-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database Configuration (PostgreSQL - optional)
DB_NAME=hillsafe_db
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

# API Keys (if you have them)
WEATHER_API_KEY=your-weather-api-key
SATELLITE_API_KEY=your-satellite-api-key
```

**For development**: The default settings work fine with SQLite (no changes needed).

**For production**: Update the `SECRET_KEY` and database credentials.

```

### Step 6: Run Database Migrations
```bash
python manage.py makemigrations
python manage.py migrate
```

### Step 7: Create Superuser (Optional)
```bash
python manage.py createsuperuser
```

### Step 8: Start Development Server
```bash
python manage.py runserver
```

The backend API will be available at: `http://127.0.0.1:8000/`

---

## Frontend Setup (Flutter)

### Step 1: Install Flutter SDK
Download and install Flutter from: https://flutter.dev/docs/get-started/install

Verify installation:
```bash
flutter doctor
```

### Step 2: Navigate to Flutter Directory
```bash
cd flutter_application_2
```

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Configure API Endpoint
Update the API base URL in the app to point to your backend:
- Open `lib/services/api_service.dart`
- Update the `baseUrl` to match your backend server (e.g., `http://127.0.0.1:8000/api/`)

### Step 5: Set Up Android Emulator or Physical Device
**For Android Emulator:**
```bash
flutter emulators --launch <emulator_id>
```

**For Physical Device:**
- Enable Developer Options and USB Debugging on your Android device
- Connect via USB

### Step 6: Run the Application
```bash
flutter run
```

For specific platforms:
```bash
flutter run -d android    # Run on Android
flutter run -d ios        # Run on iOS (macOS only)
flutter run -d chrome     # Run on Web
```

---

## Common Issues & Troubleshooting

### Backend Issues

**Issue: `ModuleNotFoundError` for dependencies**
```bash
pip install -r requirements.txt --force-reinstall
```

**Issue: Database migration errors**
```bash
python manage.py migrate --run-syncdb
```

**Issue: Port 8000 already in use**
```bash
python manage.py runserver 8080  # Use different port
```

### Frontend Issues

**Issue: Flutter doctor shows errors**
```bash
flutter doctor -v  # Detailed diagnostics
```

**Issue: Gradle build fails (Android)**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

**Issue: Packages not found**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

**Issue: API connection fails**
- Ensure backend server is running
- Check API endpoint URL in `api_service.dart`
- For Android emulator, use `http://10.0.2.2:8000/` instead of `localhost`

---

## Running Both Frontend and Backend Together

### Terminal 1 - Backend
```bash
cd backend
venv\Scripts\activate  # On Windows
python manage.py runserver
```

### Terminal 2 - Frontend
```bash
cd flutter_application_2
flutter run
```

---

## Additional Configuration

### Firebase Setup (for Push Notifications)
1. Create a Firebase project at https://console.firebase.google.com/
2. Download `google-services.json` (Android) and place in `flutter_application_2/android/app/`
3. Download `GoogleService-Info.plist` (iOS) and place in `flutter_application_2/ios/Runner/`
4. Update Firebase configuration in the backend

### PostgreSQL Setup (Production)
1. Install PostgreSQL
2. Create a database:
   ```sql
   CREATE DATABASE hillsafe_db;
   ```
3. Update `.env` file:
   ```
   DATABASE_URL=postgresql://username:password@localhost:5432/hillsafe_db
   ```
4. Run migrations again

---

## Development Workflow

1. **Start Backend**: Always start the Django server first
2. **Start Frontend**: Launch the Flutter app
3. **Test API**: Use tools like Postman or the Django admin panel at `http://127.0.0.1:8000/admin/`
4. **Hot Reload**: Flutter supports hot reload - press `r` in the terminal while the app is running

---

## Useful Commands

### Backend
```bash
python manage.py makemigrations  # Create new migrations
python manage.py migrate         # Apply migrations
python manage.py createsuperuser # Create admin user
python manage.py runserver       # Start development server
python manage.py test            # Run tests
```

### Frontend
```bash
flutter pub get              # Install dependencies
flutter clean                # Clean build files
flutter run                  # Run app
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
flutter test                 # Run tests
```
