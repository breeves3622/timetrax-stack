FROM php:8.0-apache

# Install system dependencies & PostgreSQL development libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libzip-dev \
    libxml2-dev \
    libicu-dev \
    libldap2-dev \
    unzip \
    curl \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure & Install PHP extensions required by TimeTrex
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_pgsql \
        pgsql \
        gd \
        bcmath \
        zip \
        soap \
        intl \
        ldap \
        opcache

# Enable Apache ModRewrite & set ServerName
RUN a2enmod rewrite && echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Configure PHP settings for TimeTrex compatibility & error suppression
RUN { \
    echo 'memory_limit = 512M'; \
    echo 'max_execution_time = 300'; \
    echo 'post_max_size = 100M'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'display_errors = Off'; \
    echo 'display_startup_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'error_reporting = E_ALL & ~E_NOTICE & ~E_STRICT & ~E_DEPRECATED & ~E_WARNING'; \
    echo 'date.timezone = UTC'; \
} > /usr/local/etc/php/conf.d/timetrex.ini

WORKDIR /var/www/html

# Download official TimeTrex Community Edition zip archive via curl
RUN curl -sSL "https://github.com/aydancoskun/timetrex-community-edition/archive/refs/heads/master.zip" -o /tmp/timetrex.zip \
    && unzip -q /tmp/timetrex.zip -d /tmp/ \
    && cp -R /tmp/timetrex-community-edition-master/* /var/www/html/ \
    && rm -rf /tmp/timetrex* \
    && chown -R www-data:www-data /var/www/html

# Create persistent storage directories
RUN mkdir -p /var/www/html/storage/storage && chown -R www-data:www-data /var/www/html/storage

# Add entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
