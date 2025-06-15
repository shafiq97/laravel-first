#!/bin/bash

# Railway deployment script for Laravel

echo "Starting Railway deployment..."

# Set UTF-8 locale
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8

# Set environment to production
export APP_ENV=production

# Generate application key if not set
if [ -z "$APP_KEY" ]; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# Run database migrations
echo "Running database migrations..."
php artisan migrate --force

# Clear and cache configuration
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set proper permissions
chmod -R 775 storage bootstrap/cache

echo "Railway deployment completed successfully!"
