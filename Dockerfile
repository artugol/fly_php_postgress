FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/Listen 80/Listen 8080/' \
    /etc/apache2/ports.conf \
    /etc/apache2/sites-available/000-default.conf

ENV APACHE_DOCUMENT_ROOT /var/www/html/src
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf

RUN a2enmod rewrite

COPY . /var/www/html/
RUN chown -R www-data:www-data /var/www/html

RUN echo '#!/bin/bash
set -e
if [ -n "$DATABASE_URL" ]; then
  psql "$DATABASE_URL" -tc "SELECT 1 FROM information_schema.tables LIMIT 1" | grep -q 1 \
    || psql "$DATABASE_URL" -f /var/www/html/sql/init.sql
fi
apache2-foreground' > /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
