#!/bin/bash
set -e

echo "======================================"
echo "Railway Migration Script"
echo "======================================"

echo ""
echo "1. Running database migrations..."
python manage.py migrate --noinput

echo ""
echo "2. Creating superuser if needed..."
python manage.py shell << END
from django.contrib.auth import get_user_model
import os

User = get_user_model()
admin_email = os.getenv('DJANGO_SUPERUSER_EMAIL', 'admin@lexcom.tech')
admin_password = os.getenv('DJANGO_SUPERUSER_PASSWORD', 'changeme123')

if not User.objects.filter(email=admin_email).exists():
    User.objects.create_superuser(
        email=admin_email,
        username='admin',
        password=admin_password
    )
    print(f'✅ Superuser created: {admin_email}')
else:
    print(f'ℹ️  Superuser already exists: {admin_email}')
END

echo ""
echo "3. Collecting static files..."
python manage.py collectstatic --noinput

echo ""
echo "======================================"
echo "✅ Migration completed successfully!"
echo "======================================"
