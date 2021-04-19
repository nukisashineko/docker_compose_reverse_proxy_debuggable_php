FROM php:7.2-apache
RUN pear channel-update pear.php.net
RUN pecl install xdebug && docker-php-ext-enable xdebug
WORKDIR /var/www/


COPY blog1.nginx.com/etc/apache2/sites-available/virtualhost.conf /etc/apache2/sites-available/virtualhost.conf
RUN a2enmod ssl
