FROM php:7.2-apache
RUN pear channel-update pear.php.net
RUN pecl install xdebug && docker-php-ext-enable xdebug
WORKDIR /var/www/

