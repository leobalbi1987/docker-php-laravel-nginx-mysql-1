FROM php:8.2-fpm

# Instalação de dependências e extensões necessárias
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libmemcached-dev \
    libssl-dev \
    zlib1g-dev \
    zip \
    unzip

# Configuração e instalação da extensão GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Instalação das extensões para banco de dados MySQL
RUN docker-php-ext-install mysqli pdo pdo_mysql \
    && docker-php-ext-enable pdo_mysql

# Instalação e ativação do Redis
RUN pecl install redis-5.3.7 \
    && docker-php-ext-enable redis

# Instalação e ativação do Xdebug
RUN pecl install xdebug-3.2.1 \
    && docker-php-ext-enable xdebug

# Instalação e ativação do Memcached
RUN pecl install memcached-3.2.0 \
    && docker-php-ext-enable memcached

# Instalação do Composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

# Configuração do PHP (timezone e configurações do OPcache)
RUN echo 'date.timezone="America/Sao_Paulo"' >> /usr/local/etc/php/conf.d/date.ini \
    && echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/opcache.conf \
    && echo 'opcache.validate_timestamps=1' >> /usr/local/etc/php/conf.d/opcache.conf \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache.conf

# Copia o script de geração do .env para o contêiner
COPY generate_env.sh /usr/local/bin/generate_env.sh
RUN chmod +x /usr/local/bin/generate_env.sh

# Executa o script para gerar o arquivo .env
RUN /usr/local/bin/generate_env.sh

# Define o diretório de trabalho
WORKDIR /var/www/projects/example-app

# Instalação de dependências do Laravel
RUN composer install --no-dev --optimize-autoloader \
    && chown -R www-data:www-data /var/www/projects/example-app/storage /var/www/projects/example-app/bootstrap/cache

CMD ["php-fpm"]
