# Use the official PHP image
FROM php:8.2-cli

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Copy package files
COPY package*.json ./

# Install Node dependencies
RUN npm ci --silent

# Copy application code
COPY . .

# Build frontend assets
RUN npm run build

# Generate optimized files
RUN php artisan config:cache || true
RUN php artisan route:cache || true  
RUN php artisan view:cache || true

# Set permissions
RUN chmod -R 775 storage bootstrap/cache

# Expose port (Railway will set PORT env var)
EXPOSE $PORT

# Start the application
CMD php artisan serve --host=0.0.0.0 --port=$PORT
