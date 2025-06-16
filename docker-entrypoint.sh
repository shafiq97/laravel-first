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
if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_DATABASE" ]; then
    echo "MySQL database available, running setup..."
    echo "Database: $MYSQL_DATABASE on $MYSQL_HOST:$MYSQL_PORT"
    
    # Wait for database to be ready
    echo "Waiting for database connection..."
    for i in {1..30}; do
        if php artisan migrate:status --no-interaction 2>/dev/null; then
            echo "Database connection successful"
            break
        fi
        echo "Attempt $i: Database not ready, waiting..."
        sleep 2
    done
    
    # Generate app key if needed (only if no error)
    if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
        echo "Generating application key..."
        timeout 10 php artisan key:generate --force --no-interaction || echo "Key generation failed - will try basic key"
        
        # If artisan key:generate failed, create a basic key
        if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
            echo "Creating manual APP_KEY..."
            MANUAL_KEY=$(openssl rand -base64 32)
            sed -i "s/APP_KEY=/APP_KEY=base64:$MANUAL_KEY/" .env || echo "Manual key generation failed"
        fi
    fi
    
    # Run migrations (only if no error)
    echo "Running migrations..."
    timeout 60 php artisan migrate --force --no-interaction 2>/dev/null || echo "Migrations skipped (this is normal on first run)"
else
    echo "No MySQL database configured, skipping Laravel setup commands"
    echo "Available env vars:"
    env | grep -E "(MYSQL_|DB_)" | sort || echo "No database env vars found"
fi

echo "Starting PHP development server on 0.0.0.0:$PORT"

# Use PHP's built-in server - completely bypass Laravel serve
cd public
exec php -S 0.0.0.0:$PORT
