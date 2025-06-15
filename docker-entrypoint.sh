#!/bin/bash
set -e

# Set default port if not provided
export PORT=${PORT:-8080}

# Wait a moment for any database to be ready (if needed)
sleep 2

# Run Laravel setup commands
echo "Setting up Laravel application..."

# Generate app key if needed
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction
fi

# Run database migrations (if database is available)
echo "Running database migrations..."
php artisan migrate --force --no-interaction || echo "Migration failed, continuing..."

# Cache configuration for production
echo "Caching configuration..."
php artisan config:cache || echo "Config cache failed, continuing..."
php artisan route:cache || echo "Route cache failed, continuing..."
php artisan view:cache || echo "View cache failed, continuing..."

echo "Starting Laravel development server on 0.0.0.0:$PORT"

# Start the Laravel server
exec php artisan serve --host=0.0.0.0 --port=$PORT
