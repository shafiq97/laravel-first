#!/bin/bash
set -e

# Set default port if not provided
export PORT=${PORT:-8080}

echo "Starting Laravel application setup..."

# Ensure .env file exists with basic content if not provided by Railway
if [ ! -f .env ]; then
    echo "Creating .env file from example..."
    cp .env.example .env
fi

# Generate app key if not set
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction
    export APP_KEY=$(grep APP_KEY .env | cut -d '=' -f2)
fi

# Wait a moment for database to be ready (if applicable)
echo "Waiting for database connection..."
sleep 3

# Try to run migrations (ignore if database not available)
echo "Attempting to run migrations..."
php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped (database not available)"

# Clear and optimize caches for production
echo "Optimizing application..."
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Only cache if we have a proper environment
if [ "$APP_ENV" = "production" ]; then
    php artisan config:cache 2>/dev/null || echo "Config cache skipped"
    php artisan route:cache 2>/dev/null || echo "Route cache skipped"
    php artisan view:cache 2>/dev/null || echo "View cache skipped"
fi

echo "Starting Laravel development server on 0.0.0.0:$PORT"

# Start the Laravel server
exec php artisan serve --host=0.0.0.0 --port=$PORT
