#!/bin/bash
set -e

echo "Starting Laravel application..."

# Handle PORT properly
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Setup environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    if [ -f .env.example ]; then
        cp .env.example .env
    elif [ -f .env.build ]; then
        cp .env.build .env
    else
        # Create minimal .env file
        cat > .env << EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

DB_CONNECTION=mysql
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

LOG_CHANNEL=stack
LOG_LEVEL=error
EOF
    fi
fi

# Only run setup commands if we have database connection
if [ -n "$DB_HOST" ] && [ -n "$DB_DATABASE" ]; then
    echo "Database available, running setup..."
    
    # Generate app key if needed (only if no error)
    if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
        echo "Generating application key..."
        timeout 10 php artisan key:generate --force --no-interaction 2>/dev/null || echo "Key generation skipped"
    fi
    
    # Run migrations (only if no error)
    echo "Running migrations..."
    timeout 30 php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped"
else
    echo "No database configured, skipping Laravel setup commands"
fi

echo "Starting PHP development server on 0.0.0.0:$PORT"

# Use PHP's built-in server - completely bypass Laravel serve
cd public
exec php -S 0.0.0.0:$PORT
