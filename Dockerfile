FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Apache en puerto 8080
# Railway detecta el puerto automáticamente, pero 8080 es un estándar seguro.
RUN sed -i 's/Listen 80/Listen ${PORT}/' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/' /etc/apache2/sites-available/000-default.conf

# 3. Habilitar mod_rewrite y asegurar un solo MPM
# Forzamos a que use mpm_prefork para evitar el error AH00534
RUN a2dismod mpm_event || true && a2enmod mpm_prefork rewrite

# 4. Copiar archivos
COPY src/index.php /var/www/html/index.php
COPY sql/init.sql /sql/init.sql

# 5. Permisos
RUN chown -R www-data:www-data /var/www/html

# 6. Entrypoint corregido
# Usamos una variable de entorno para el puerto que Railway asigna ($PORT)
RUN printf '%s\n' \
'#!/bin/bash' \
'set -e' \
'' \
'if [ -n "$DATABASE_URL" ] && [ -f /sql/init.sql ]; then' \
'  echo "Inicializando base de datos..."' \
'  psql "$DATABASE_URL" -f /sql/init.sql || true' \
'fi' \
'' \
'# Iniciar Apache en primer plano' \
'exec apache2-foreground' \
> /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Railway usa la variable PORT dinámicamente
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
