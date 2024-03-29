FROM php:7.2-apache

# Enable Apache Rewrite + Expires Module
RUN a2enmod rewrite expires

# Install dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libyaml-dev \
    && docker-php-ext-install opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

RUN pecl install apcu \
    && pecl install yaml \
    && pecl install xdebug

RUN { \
    echo "extension=apcu.so"; \
    echo "extension=yaml.so"; \
    echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)"; \
    echo '[XDebug]'; \
    echo 'xdebug.default_enable=1'; \
    echo 'xdebug.remote_autostart=1'; \
    echo 'xdebug.remote_connect_back=0'; \
    echo 'xdebug.remote_enable=1'; \
    echo 'xdebug.remote_host=host.docker.internal'; \
    echo 'xdebug.remote_log=/tmp/xdebug.log'; \
    echo 'xdebug.remote_port=9073'; \
    } > /usr/local/etc/php/conf.d/php-recommended.ini

# Set user to www-data
RUN chown www-data:www-data /var/www
USER www-data

# Define Grav version and expected SHA1 signature
ENV GRAV_VERSION 1.6.23
ENV GRAV_SHA1 47c5e548783c66dbf12ba3519c2860d8511d97b5

# Install grav
WORKDIR /var/www
RUN curl -o grav.zip -SL https://getgrav.org/download/core/grav/${GRAV_VERSION} && \
    echo "$GRAV_SHA1 grav.zip" | sha1sum -c - && \
    unzip grav.zip && \
    mv -T /var/www/grav /var/www/html && \
    rm grav.zip

# Install simplesearch plugin
RUN cd /var/www/html && bin/gpm install simplesearch

# Return to root user
USER root
