@echo off
REM HillSafe AI Backend Setup Script
REM Automatically creates Django project and apps

echo ========================================
echo HillSafe AI - Backend Setup
echo ========================================
echo.

REM Activate virtual environment
echo [1/6] Activating virtual environment...
call venv\Scripts\activate.bat

REM Create Django project
echo [2/6] Creating Django project 'hillsafe_core'...
python -m django startproject hillsafe_core .

REM Create accounts app
echo [3/6] Creating 'accounts' app...
python manage.py startapp accounts

REM Create regions app
echo [4/6] Creating 'regions' app...
python manage.py startapp regions

REM Create data_ingestion app
echo [5/6] Creating 'data_ingestion' app...
python manage.py startapp data_ingestion

REM Create predictions app
echo [6/6] Creating 'predictions' app...
python manage.py startapp predictions

REM Create alerts app
echo [7/7] Creating 'alerts' app...
python manage.py startapp alerts

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Directory structure:
dir /B /AD
echo.
echo Next steps:
echo 1. Configure hillsafe_core/settings.py
echo 2. Run: python manage.py migrate
echo 3. Run: python manage.py createsuperuser
echo 4. Run: python manage.py runserver
echo.
pause
