#!/bin/bash
set -e

echo "Starting Laravel application..."

# Handle PORT properly
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Setup environment
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    elif [ -f .env.build ]; then
        cp .env.build .env
    fi
fi

# Generate app key if needed
if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction 2>/dev/null || true
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped"

# Clear any cached config
php artisan config:clear 2>/dev/null || true

echo "Starting PHP development server on 0.0.0.0:$PORT"

# Use PHP's built-in server - this avoids the Laravel serve command bug
cd public
exec php -S 0.0.0.0:$PORT
