FROM php:7.0-apache
RUN pecl install xdebug && docker-php-ext-enable xdebug
WORKDIR /var/www/

