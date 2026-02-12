web: gunicorn core.wsgi:application --bind [::]:$PORT --workers 4 --threads 2 --timeout 300 --log-file - --access-logfile - --error-logfile -
release: python manage.py migrate --noinput
