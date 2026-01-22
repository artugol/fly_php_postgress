FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Apache en puerto 8080 (Fly.io)
RUN sed -i 's/Listen 80/Listen 8080/' \
    /etc/apache2/ports.conf \
    /etc/apache2/sites-available/000-default.conf

# 3. Habilitar mod_rewrite (opcional pero recomendado)
RUN a2enmod rewrite

# 4. Copiar SOLO index.php desde src al DocumentRoot real
COPY src/index.php /var/www/html/index.php

# (opcional) si tienes otros assets
# COPY src/assets /var/www/html/assets

# 5. Permisos
RUN chown -R www-data:www-data /var/www/html

# 6. Entrypoint mínimo (sin lógica extra)
EXPOSE 8080

CMD ["apache2-foreground"]
