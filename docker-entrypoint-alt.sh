#!/bin/bash
set -e

echo "Starting Laravel application..."

# Get the port from environment, default to 8080
PORT=${PORT:-8080}

echo "Using port: $PORT"

# Setup .env file
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
    elif [ -f .env.build ]; then
        cp .env.build .env
    fi
fi

# Generate app key
if [ -z "$APP_KEY" ] || ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction 2>/dev/null || true
fi

# Migrations
echo "Running migrations..."
php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped"

# Clear cache
php artisan config:clear 2>/dev/null || true

echo "Starting PHP server on 0.0.0.0:$PORT"

# Create a simple script to handle the serve command issue
cat > /tmp/serve.php << 'EOF'
<?php
$port = $_SERVER['PORT'] ?? 8080;
$host = '0.0.0.0';

echo "Starting Laravel development server: http://$host:$port\n";
echo "[Ctrl+C to quit]\n";

$cmd = "php -S $host:$port -t public public/index.php";
passthru($cmd);
EOF

PORT=$PORT php /tmp/serve.php
