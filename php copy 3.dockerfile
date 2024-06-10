# Use a imagem base PHP 8.2 FPM
FROM php:8.2-fpm

# Atualiza o sistema e instala as dependências básicas
RUN apt-get update && apt-get install -y \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libmemcached-dev \
    libssl-dev \
    zlib1g-dev \
    zip \
    unzip \
    curl

# Instala extensões PHP necessárias
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && docker-php-ext-enable pdo_mysql

# Instala Redis, Xdebug e Memcached
RUN if ! pecl list | grep -q '^redis'; then pecl install redis-5.3.7 && docker-php-ext-enable redis; fi \
    && if ! pecl list | grep -q '^xdebug'; then pecl install xdebug-3.2.1 && docker-php-ext-enable xdebug; fi \
    && if ! pecl list | grep -q '^memcached'; then pecl install memcached-3.2.0 && docker-php-ext-enable memcached; fi

# Instala Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configurações adicionais do PHP
RUN echo 'date.timezone="America/Sao_Paulo"' >> /usr/local/etc/php/conf.d/date.ini \
    && echo 'opcache.enable=1' >> /usr/local/etc/php/conf.d/opcache.conf \
    && echo 'opcache.validate_timestamps=1' >> /usr/local/etc/php/conf.d/opcache.conf \
    && echo 'opcache.fast_shutdown=1' >> /usr/local/etc/php/conf.d/opcache.conf

# Define o diretório de trabalho
WORKDIR /var/www/projects/example-app

# Copia o código do seu projeto para dentro do contêiner
COPY ./projects/example-app /var/www/projects/example-app

# Executa o Composer para instalar as dependências do Laravel
RUN composer install --no-dev --optimize-autoloader
# Copia o arquivo .env.example para .env
COPY ./projects/example-app/.env.example /var/www/projects/example-app/.env

# Define permissões adequadas para o Laravel
RUN chown -R www-data:www-data /var/www/projects/example-app/storage /var/www/projects/example-app/bootstrap/cache

# Comando padrão para iniciar o container
CMD ["php-fpm"]
