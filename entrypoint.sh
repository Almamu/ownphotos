#! /bin/bash
export PYTHONUNBUFFERED=TRUE

# copy nginx configuration
cp nginx.conf /etc/nginx/sites-enabled/default
# run nginx as root - see https://github.com/hooram/ownphotos/issues/78
sed -i -e 's/user www-data/user root/g' /etc/nginx/nginx.conf

service nginx restart

python image_similarity/main.py 2>&1 | tee logs/gunicorn_image_similarity.log &

python manage.py makemigrations api 2>&1 | tee logs/command_makemigrations.log
python manage.py migrate 2>&1 | tee logs/command_migrate.log
python manage.py build_similarity_index 2>&1 | tee logs/command_build_similarity_index.log

python manage.py shell <<EOF
from api.models import User

if User.objects.filter(username="$ADMIN_USERNAME").exists():
    admin_user = User.objects.get(username="$ADMIN_USERNAME")
    admin_user.set_password("$ADMIN_PASSWORD")
    admin_user.save()
else:
    User.objects.create_superuser('$ADMIN_USERNAME', '$ADMIN_EMAIL', '$ADMIN_PASSWORD')
EOF

echo "Running backend server..."

python manage.py rqworker default 2>&1 | tee logs/rqworker.log &
gunicorn --workers=2 --worker-class=gevent --bind 0.0.0.0:8000 --log-level=info ownphotos.wsgi 2>&1 | tee logs/gunicorn_django.log

