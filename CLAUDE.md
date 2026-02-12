# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Django REST API backend for Lexcom, a marketing automation platform that provides AI-powered content generation (video structures, ad copy, landing pages) and TikTok integration. The API uses JWT authentication and integrates with OpenAI, TikTok APIs, and machine learning models for predictions.

## Environment Setup

### Prerequisites
- Python 3.10+ (Dockerfile uses 3.10-slim)
- PostgreSQL 14.1+
- Virtual environment (venv or .venv)

### Initial Setup
```bash
# Create and activate virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements/requirements.txt

# Start PostgreSQL database
docker-compose up -d

# Run migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput
```

### Environment Variables
Create a `.env` file in the project root with:
- `SECRET_KEY` - Django secret key
- `DATABASE_PASSWORD` - PostgreSQL password
- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` - Database connection
- `DEBUG` - Set to False in production
- `DEVELOPER_ACCESS_TOKEN` / `PRODUCTION_ACCESS_TOKEN` - API access tokens
- `PASSWORD_APP_LEXCOM_SUPPORT` - SMTP password for email
- `CLIENT_ID_GOOGLE`, `SECRET_GOOGLE` - Google OAuth credentials
- ML model files should be placed in `api/IAmodels/` (gitignored)

## Common Commands

### Development
```bash
# Run development server
python manage.py runserver

# Run development server on specific port
python manage.py runserver 0.0.0.0:8000

# Run tests
python manage.py test

# Run specific test
python manage.py test api.tests.TestClassName

# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Access Django shell
python manage.py shell
```

### Docker
```bash
# Build and run with Docker
docker-compose up -d

# Build Docker image
docker build -t lexcom-server .

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Production
```bash
# Collect static files (required before deployment)
python manage.py collectstatic --noinput

# Run with Gunicorn (production)
gunicorn core.wsgi:application --bind 0.0.0.0:8000 --workers 2 --threads 4 --timeout 300
```

## Architecture

### Core Structure
- **`core/`** - Django project configuration
  - `settings.py` - Central configuration (database, JWT, CORS, static files, email)
  - `urls.py` - Root URL routing (admin, api/v1/)
  - `models.py` - Custom User model with subscription plans
  - `wsgi.py` / `asgi.py` - WSGI/ASGI application entry points

- **`api/`** - Main application with all business logic
  - `views/` - API endpoints organized by domain (user, openai, tiktok, lexcomia, payment, etc.)
  - `serializers/` - DRF serializers for data validation
  - `BackendClient/` - External service integrations (OpenAI, TikTok, Payment, LexcomIA)
  - `urls.py` - API route definitions (all under `/api/v1/` prefix)

### Authentication Flow
- JWT-based authentication using `djangorestframework-simplejwt`
- Token management: `/api/v1/token/` (obtain), `/api/v1/token/refresh/` (refresh)
- Google OAuth integration via django-allauth
- Custom User model extends AbstractUser with email as USERNAME_FIELD
- Tokens stored in cookies (`access`, `refresh`)
- Token lifetime: 240 minutes (access), 1 day (refresh)

### Subscription System
User model includes tiered subscription plans:
- **Free**: 8 searches allowed
- **Standard**: 35 searches allowed
- **Business**: 50 searches allowed
- **Premium**: 100 searches allowed

Search tracking managed via `search_count` and `progress_count` fields.

### External Integrations

**OpenAI Client** (`api/BackendClient/openai.py`)
- Uses `gpt-3.5-turbo-instruct` model
- Three main functions: video structures, ad copy, landing page generation
- All prompts are in Spanish

**TikTok Client** (`api/BackendClient/tiktok.py`)
- Fetches video interest data by user ID

**LexcomIA Client** (`api/BackendClient/lexcomia.py`)
- Loads scikit-learn models from `api/IAmodels/` directory
- Two models: `random_forest.joblib` (5-class), `logistic_regresion.joblib` (binary)
- Transforms boolean features to binary arrays for predictions

**Payment Client** (`api/BackendClient/payment.py`)
- MercadoPago integration for subscription payments

### Key API Endpoints
All endpoints are prefixed with `/api/v1/`:
- `/register/` - User registration
- `/token/` - JWT token obtain
- `/logout/` - Token blacklist
- `/openai/<id>` - Video structure generation
- `/copy_ads/<id>` - Ad copy generation
- `/landing/<id>` - Landing page generation
- `/tiktok/<id>` - TikTok video interest data
- `/lexcom_five_class/` - ML predictions (POST)
- `/update_plan/` - Update user subscription
- `/increment_search_count/` - Track search usage
- `/password_reset/` - Password reset flow

### Database
- PostgreSQL (default: lexcom_db on localhost:5432)
- Single custom User model in core app
- Migrations in `core/migrations/`
- Password reset uses django-rest-passwordreset with email signals

### Static Files
- Collected to `staticfiles/` directory
- Served via WhiteNoise with compression
- ML models stored in `api/IAmodels/` (excluded from git)

## Development Notes

- DEBUG=False in settings (verify before local development)
- CORS configured to allow all origins (`CORS_ALLOW_ALL_ORIGINS = True`)
- Email backend uses Gmail SMTP (suptechlexcom1@gmail.com)
- Static files must be collected before deployment
- ML model files are gitignored and must be deployed separately
- Dockerfile uses Python 3.10 and installs gunicorn for production
