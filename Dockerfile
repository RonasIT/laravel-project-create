FROM webdevops/php-nginx:8.4-alpine

ENV WEB_DOCUMENT_ROOT /app/public
ENV WEB_DOCUMENT_INDEX index.php

WORKDIR /app
COPY --chown=application:www-data . /app

USER application
RUN composer install --no-dev --optimize-autoloader \
    && php artisan storage:link
