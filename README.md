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

## Getting Started

### Prerequisites
- Python 3.8+
- Flutter SDK
- Android Studio / VS Code

### Backend Setup
1. Navigate to the `backend` directory.
2. Create and activate a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run migrations and start the server:
   ```bash
   python manage.py migrate
   python manage.py runserver
   ```

### Frontend Setup
1. Navigate to `flutter_application_2`.
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```
