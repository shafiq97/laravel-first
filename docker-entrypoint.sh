#!/bin/bash
set -e

echo "Starting Laravel application..."

# Handle PORT properly
PORT=${PORT:-8080}
echo "Using port: $PORT"

# Setup environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    if [ -f .env.production ]; then
        cp .env.production .env
        echo "Copied .env.production to .env"
    elif [ -f .env.example ]; then
        cp .env.example .env
        echo "Copied .env.example to .env"
    elif [ -f .env.build ]; then
        cp .env.build .env
        echo "Copied .env.build to .env"
    else
        # Create minimal .env file
        cat > .env << EOF
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost

DB_CONNECTION=mysql
SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync

LOG_CHANNEL=stack
LOG_LEVEL=error
EOF
        echo "Created minimal .env file"
    fi
fi

# Always ensure APP_KEY is set
if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
    echo "Generating application key..."
    # Try artisan first
    if timeout 10 php artisan key:generate --force --no-interaction 2>/dev/null; then
        echo "APP_KEY generated successfully with artisan"
    else
        echo "Artisan failed, creating manual APP_KEY..."
        MANUAL_KEY=$(openssl rand -base64 32)
        sed -i "s/APP_KEY=/APP_KEY=base64:$MANUAL_KEY/" .env
        echo "Manual APP_KEY created"
    fi
fi

# Only run setup commands if we have database connection
if [ -n "$MYSQL_HOST" ] && [ -n "$MYSQL_DATABASE" ]; then
    echo "MySQL database available, running setup..."
    echo "Database: $MYSQL_DATABASE on $MYSQL_HOST:$MYSQL_PORT"
    
    # Wait for database to be ready and test connection
    echo "Waiting for database connection..."
    DB_READY=false
    for i in {1..60}; do
        if php -r "
            try {
                \$pdo = new PDO('mysql:host=$MYSQL_HOST;port=$MYSQL_PORT;dbname=$MYSQL_DATABASE', '$MYSQL_USER', '$MYSQL_PASSWORD');
                echo 'Database connection successful';
                exit(0);
            } catch (Exception \$e) {
                echo 'Connection failed: ' . \$e->getMessage();
                exit(1);
            }
        " 2>/dev/null; then
            DB_READY=true
            echo "Database connection verified!"
            break
        fi
        echo "Attempt $i/60: Database not ready, waiting..."
        sleep 3
    done
    
    if [ "$DB_READY" = true ]; then
        # Check if migrations table exists
        echo "Checking migration status..."
        if php artisan migrate:status --no-interaction 2>/dev/null; then
            echo "Migration table exists, checking for pending migrations..."
        else
            echo "Migration table doesn't exist, running initial migrations..."
        fi
        
        # Run migrations with more verbose output
        echo "Running database migrations..."
        php artisan migrate --force --no-interaction -v || {
            echo "Migrations failed, trying to create database first..."
            php artisan migrate:install --no-interaction 2>/dev/null || true
            php artisan migrate --force --no-interaction -v || echo "Migrations still failing, will continue without them"
        }
        
        # Show final migration status
        echo "Final migration status:"
        php artisan migrate:status --no-interaction 2>/dev/null || echo "Cannot check migration status"
        
    else
        echo "Database connection failed after 3 minutes, continuing without migrations"
    fi
else
    echo "No MySQL database configured, skipping Laravel setup commands"
    echo "Available env vars:"
    env | grep -E "(MYSQL_|DB_)" | sort || echo "No database env vars found"
    echo ""
    echo "To add MySQL database:"
    echo "1. Go to Railway Dashboard"
    echo "2. Click '+ New' → Database → MySQL"
    echo "3. Railway will auto-connect it to this service"
fi

echo "Starting PHP development server on 0.0.0.0:$PORT"

# Use PHP's built-in server - completely bypass Laravel serve
cd public
exec php -S 0.0.0.0:$PORT
