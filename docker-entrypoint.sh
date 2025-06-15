#!/bin/bash
set -e

echo "Starting Laravel application..."

# Handle PORT environment variable properly
if [ -z "$PORT" ]; then
    PORT=8080
fi

# Ensure PORT is a valid integer
if ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
    echo "Invalid PORT value: $PORT, using 8080"
    PORT=8080
fi

echo "Using port: $PORT"

# Create .env if it doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    elif [ -f .env.build ]; then
        cp .env.build .env
    else
        echo "APP_KEY=" > .env
    fi
fi

# Generate app key if needed
if [ -z "$APP_KEY" ] || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction || echo "Key generation failed, continuing..."
fi

# Try migrations (fail silently if no database)
echo "Running migrations..."
php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped"

# Clear caches
php artisan config:clear 2>/dev/null || true

echo "Starting server on 0.0.0.0:$PORT"

# Start Laravel with explicit port parameter
exec php artisan serve --host=0.0.0.0 --port="$PORT"
