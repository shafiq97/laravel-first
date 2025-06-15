# Use PHP with CLI
FROM php:8.2-cli

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Set working directory
WORKDIR /app

# Copy application files
COPY . .

# Create .env file for build process (will be overridden at runtime)
RUN cp .env.build .env

# Install PHP dependencies with more permissive settings
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs || \
    composer install --no-dev --no-interaction --ignore-platform-reqs

# Install Node dependencies and build
RUN npm install --silent && npm run build

# Set permissions
RUN chmod -R 775 storage bootstrap/cache 2>/dev/null || true
RUN mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache

# Default port
ENV PORT=8080
EXPOSE $PORT

# Copy startup script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Use startup script
CMD ["/usr/local/bin/docker-entrypoint.sh"]
