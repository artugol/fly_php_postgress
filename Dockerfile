FROM php:8.2-apache

# 1. Dependencias PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Configuración de puertos dinámica para Railway
RUN sed -i "s/Listen 80/Listen \${PORT}/" /etc/apache2/ports.conf \
    && sed -i "s/<VirtualHost \*:80>/<VirtualHost *:\${PORT}>/" /etc/apache2/sites-available/000-default.conf

# 3. Habilitar mod_rewrite
RUN a2enmod rewrite

# 4. Copiar archivos del proyecto
COPY src/index.php /var/www/html/index.php
COPY sql/init.sql /sql/init.sql

# 5. Permisos para que Apache pueda leer los archivos
RUN chown -R www-data:www-data /var/www/html

# 6. EL REPARADOR DE APACHE (Entrypoint)
# Este script borra los módulos que causan el error AH00534 justo antes de arrancar
RUN printf '%s\n' \
'#!/bin/bash' \
'set -e' \
'' \
'echo "--- ELIMINANDO CONFLICTOS DE MPM ---"' \
'# Borramos cualquier rastro de mpm_event y mpm_worker' \
'rm -f /etc/apache2/mods-enabled/mpm_event.*' \
'rm -f /etc/apache2/mods-enabled/mpm_worker.*' \
'' \
'# Forzamos que solo exista prefork' \
'ln -sf /etc/apache2/mods-available/mpm_prefork.load /etc/apache2/mods-enabled/' \
'ln -sf /etc/apache2/mods-available/mpm_prefork.conf /etc/apache2/mods-enabled/' \
'' \
'if [ -n "$DATABASE_URL" ] && [ -f /sql/init.sql ]; then' \
'  echo "Inicializando base de datos..."' \
'  # El || true evita que el contenedor falle si la tabla ya existe' \
'  psql "$DATABASE_URL" -f /sql/init.sql || true' \
'fi' \
'' \
'echo "--- SERVIDOR LISTO Y ESTABLE ---"' \
'exec apache2-foreground' \
> /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Variable PORT necesaria para Railway
ENV PORT=8080
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
