# Use PHP with CLI
FROM php:8.2-cli

# Cache busting - change this comment to force rebuild: v2.1

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

# Copy composer files first for better layer caching
COPY composer.json composer.lock ./

# Create minimal .env file for build process
RUN echo "APP_NAME=Laravel" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_KEY=base64:$(openssl rand -base64 32)" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=http://localhost" >> .env && \
    echo "DB_CONNECTION=sqlite" >> .env && \
    echo "DB_DATABASE=/tmp/database.sqlite" >> .env && \
    touch /tmp/database.sqlite

# Install PHP dependencies without running post-install scripts first
RUN composer install --no-dev --no-scripts --optimize-autoloader --no-interaction --ignore-platform-reqs

# Copy remaining application files
COPY . .

# Now run post-install scripts with the full application available
RUN php artisan package:discover --ansi || true

# Install Node dependencies and build
COPY . .

# Create .env file for build process (will be overridden at runtime)
RUN cp .env.build .env

# Clear composer cache and install PHP dependencies with more permissive settings and verbosity
RUN composer clear-cache
RUN composer update --no-dev --no-interaction --ignore-platform-reqs -vvv || \\\
    composer update --no-dev --no-interaction --ignore-platform-reqs
RUN composer install --no-dev --optimize-autoloader --no-interaction --ignore-platform-reqs -vvv || \\\
    composer install --no-dev --no-interaction --ignore-platform-reqs -vvv

# Install Node dependencies and build
RUN npm install --silent && npm run build

# Set permissions
RUN chmod -R 775 storage bootstrap/cache 2>/dev/null || true
RUN mkdir -p storage/logs storage/framework/{cache,sessions,views} bootstrap/cache

# Default port
ENV PORT=8080
EXPOSE 8080

# Copy startup script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Use startup script
CMD ["/usr/local/bin/docker-entrypoint.sh"]
