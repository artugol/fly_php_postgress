FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Configuración de puertos (usando variable de entorno)
RUN sed -i "s/Listen 80/Listen \${PORT}/" /etc/apache2/ports.conf \
    && sed -i "s/<VirtualHost \*:80>/<VirtualHost *:\${PORT}>/" /etc/apache2/sites-available/000-default.conf

# 3. Habilitar mod_rewrite
RUN a2enmod rewrite

# 4. Copiar archivos
COPY src/index.php /var/www/html/index.php
COPY sql/init.sql /sql/init.sql

# 5. Permisos
RUN chown -R www-data:www-data /var/www/html

# 6. Entrypoint "Blindado"
# Ahora corregimos los MPMs justo antes de lanzar Apache
RUN printf '%s\n' \
'#!/bin/bash' \
'set -e' \
'' \
'# --- PASO CRÍTICO PARA EVITAR EL ERROR AH00534 ---' \
'# Desactivamos módulos que sobran y activamos el correcto en cada arranque' \
'a2dismod mpm_event || true' \
'a2dismod mpm_worker || true' \
'a2enmod mpm_prefork || true' \
'' \
'if [ -n "$DATABASE_URL" ] && [ -f /sql/init.sql ]; then' \
'  echo "Inicializando base de datos..."' \
'  psql "$DATABASE_URL" -f /sql/init.sql || true' \
'fi' \
'' \
'echo "--- APACHE INICIANDO SIN CONFLICTOS ---"' \
'exec apache2-foreground' \
> /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
