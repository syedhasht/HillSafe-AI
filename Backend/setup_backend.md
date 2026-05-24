# HillSafe AI Backend Setup Guide

## Step-by-Step Setup Commands

### 1. Create Backend Directory & Virtual Environment

```powershell
# Navigate to project root
cd C:\Users\hashi\Downloads\FYP

# Create Backend directory (already created when requirements.txt was added)
# cd Backend

# Create Python virtual environment
python -m venv venv

# Activate virtual environment
.\venv\Scripts\activate
```

### 2. Install Dependencies

```powershell
# Upgrade pip
python -m pip install --upgrade pip

# Install all dependencies
pip install -r requirements.txt
```

### 3. Initialize Django Project

```powershell
# Create Django project named 'hillsafe_core'
django-admin startproject hillsafe_core .

# Verify structure (you should see manage.py)
dir
```

### 4. Create Django Apps

```powershell
# Create accounts app (User authentication & Roles)
python manage.py startapp accounts

# Create regions app (Geographic districts & coordinates)
python manage.py startapp regions

# Create data_ingestion app (Weather/Satellite APIs)
python manage.py startapp data_ingestion

# Create predictions app (ML logic)
python manage.py startapp predictions

# Create alerts app (Notification system)
python manage.py startapp alerts
```

### 5. Verify Directory Structure

Your Backend directory should now look like:

```
Backend/
├── venv/                    # Virtual environment
├── hillsafe_core/           # Django project settings
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
├── accounts/                # App: User management
├── regions/                 # App: Geographic data
├── data_ingestion/          # App: External APIs
├── predictions/             # App: ML models
├── alerts/                  # App: Notifications
├── manage.py                # Django CLI
└── requirements.txt         # Dependencies
```

### 6. Initial Django Configuration

After setup, you'll need to:

1. **Update `hillsafe_core/settings.py`:**
   - Add apps to `INSTALLED_APPS`
   - Configure PostgreSQL database
   - Add CORS headers
   - Configure REST Framework

2. **Run initial migrations:**
   ```powershell
   python manage.py migrate
   ```

3. **Create superuser:**
   ```powershell
   python manage.py createsuperuser
   ```

4. **Run development server:**
   ```powershell
   python manage.py runserver
   ```

## Quick Start (All Commands)

```powershell
# 1. Navigate and create venv
cd C:\Users\hashi\Downloads\FYP\Backend
python -m venv venv
.\venv\Scripts\activate

# 2. Install dependencies
python -m pip install --upgrade pip
pip install -r requirements.txt

# 3. Initialize Django
django-admin startproject hillsafe_core .

# 4. Create apps
python manage.py startapp accounts
python manage.py startapp regions
python manage.py startapp data_ingestion
python manage.py startapp predictions
python manage.py startapp alerts

# 5. Verify
python manage.py check
```

## Next Steps

- Configure PostgreSQL database
- Set up models for each app
- Create API endpoints with Django REST Framework
- Integrate ML models in predictions app
- Set up CORS for Flutter app connection

## Notes

- Always activate the virtual environment before working: `.\venv\Scripts\activate`
- Use `deactivate` to exit the virtual environment
- Keep `requirements.txt` updated: `pip freeze > requirements.txt`
