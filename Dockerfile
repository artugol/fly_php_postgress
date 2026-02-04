FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Configuración de puertos (Vital para Railway)
RUN sed -i "s/Listen 80/Listen \${PORT}/" /etc/apache2/ports.conf \
    && sed -i "s/<VirtualHost \*:80>/<VirtualHost *:\${PORT}>/" /etc/apache2/sites-available/000-default.conf

# 3. AQUÍ ESTÁ LA SOLUCIÓN AL ERROR ROJO:
# Quitamos el módulo que sobra y ponemos el correcto
RUN a2dismod mpm_event || true && a2enmod mpm_prefork rewrite

# 4. Copiar archivos
COPY src/index.php /var/www/html/index.php
COPY sql/init.sql /sql/init.sql

# 5. Permisos
RUN chown -R www-data:www-data /var/www/html

# 6. Script de inicio
RUN printf '%s\n' \
'#!/bin/bash' \
'set -e' \
'' \
'if [ -n "$DATABASE_URL" ] && [ -f /sql/init.sql ]; then' \
'  echo "Inicializando base de datos..."' \
'  psql "$DATABASE_URL" -f /sql/init.sql || true' \
'fi' \
'' \
'echo "--- APACHE ARRANCANDO CORRECTAMENTE ---"' \
'exec apache2-foreground' \
> /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
