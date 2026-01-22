FROM php:8.2-apache

# 1. Instalar dependencias
RUN apt-get update && apt-get install -y \
    libpq-dev \
    postgresql-client \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Tu cadena de conexión directa
ENV DATABASE_URL="postgresql://fly-user:tPZ1lHoJxuKM7vHh3KbEB9Xh@pgbouncer.z23750v7myl096d1.flympg.net/fly-db"

# 3. Configurar puerto 8080 para Fly.io
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf

# 4. Configurar el DocumentRoot a /var/www/html/src Y habilitar permisos de carpeta
ENV APACHE_DOCUMENT_ROOT /var/www/html/src

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Añadimos esta sección para que Apache tenga permiso explícito de entrar en /src
RUN echo "<Directory ${APACHE_DOCUMENT_ROOT}>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# 5. Copiar archivos
COPY . /var/www/html/

# 6. Forzar permisos correctos (Crítico para el error 403)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# 7. Script de entrada
RUN echo '#!/bin/bash\n\
psql "$DATABASE_URL" -f /var/www/html/sql/init.sql\n\
apache2-foreground' > /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

CMD ["/usr/local/bin/docker-entrypoint.sh"]
