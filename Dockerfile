FROM php:7.2-apache

# Image based on the Wordpress docker image from:

LABEL name="grav-docker"
LABEL version="1.0.1"

# install the PHP extensions we need
RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y \
    wget \
    unzip \
    libjpeg-dev \
    libpng-dev \
    zlib1g-dev \
    libpng16-16 \
    git \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    apt-get clean && \
    \
    docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
    docker-php-ext-install gd zip opcache
# TODO consider removing the *-dev deps and only keeping the necessary lib* packages

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
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN a2enmod rewrite expires

ENV SOURCE="/usr/src/grav"
ENV PATHS="/var/www/html"
RUN set -ex; \
    wget https://getgrav.org/download/core/grav/latest && \
    unzip latest && \
    mkdir -p "$SOURCE" && \
    cp -r grav-admin/. "$SOURCE" && \
    rm -rf grav-admin latest && \
    rm -rf "$SOURCE"/user && \

    chown -R www-data:www-data "$SOURCE"

COPY ./ /var/www/html/user
COPY docker-entrypoint.sh /

COPY ./ /var/www/html/user

RUN chmod +x /docker-entrypoint.sh && \
    chown root:root /docker-entrypoint.sh

EXPOSE 80
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2-foreground"]

