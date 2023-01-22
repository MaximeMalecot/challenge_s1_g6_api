ARG PHP_VERSION=8.1
FROM php:${PHP_VERSION}-fpm-alpine

# persistent / runtime deps
RUN apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
	;

ARG APCU_VERSION=5.1.21
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
		icu-data-full \
		icu-dev \
		libzip-dev \
		zlib-dev \
	; \
	\
	docker-php-ext-configure zip; \
	docker-php-ext-install -j$(nproc) \
		intl \
		zip \
	; \
	pecl install \
		apcu-${APCU_VERSION} \
	; \
	pecl clear-cache; \
	docker-php-ext-enable \
		apcu \
		opcache \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .api-phpexts-rundeps $runDeps; \
	\
	apk del .build-deps

###> recipes ###
###> doctrine/doctrine-bundle ###
RUN apk add --no-cache --virtual .pgsql-deps postgresql-dev; \
	docker-php-ext-install -j$(nproc) pdo_pgsql; \
	apk add --no-cache --virtual .pgsql-rundeps so:libpq.so.5; \
	apk del .pgsql-deps
###< doctrine/doctrine-bundle ###
###< recipes ###

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY docker/php/conf.d/api-platform.prod.ini $PHP_INI_DIR/conf.d/api-platform.ini

COPY docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf

VOLUME /var/run/php

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

WORKDIR /srv/api

# build for production
ARG APP_ENV=prod

# prevent the reinstallation of vendors at every changes in the source code
COPY composer.json composer.lock symfony.lock ./
RUN set -eux; \
	composer install --prefer-dist --no-dev --no-scripts --no-progress; \
	composer clear-cache

# copy only specifically what we need
# COPY .env .
COPY bin bin/
COPY config config/
COPY migrations migrations/
COPY public public/
COPY src src/
COPY templates templates/

ARG TRUSTED_PROXIES \
    TRUSTED_HOSTS \
    APP_SECRET \
    DATABASE_URL \
    MAILER_DSN \
    CORS_ALLOW_ORIGIN \
    MERCURE_URL \
    MERCURE_PUBLIC_URL \
    MERCURE_JWT_SECRET \
    JWT_PASSPHRASE \
    STRIPE_PK \
    STRIPE_SK \
    STRIPE_WH_SK \
    FRONT_URL \
    KYC_API_URL \
    KYC_API_SECRET

ENV TRUSTED_PROXIES=$TRUSTED_PROXIES \
    TRUSTED_HOSTS=$TRUSTED_HOSTS \
    APP_ENV=$APP_ENV \
    APP_SECRET=$APP_SECRET \
    DATABASE_URL=$DATABASE_URL \
    MAILER_DSN=$MAILER_DSN \
    CORS_ALLOW_ORIGIN=$CORS_ALLOW_ORIGIN \
    MERCURE_URL=$MERCURE_URL \
    MERCURE_PUBLIC_URL=$MERCURE_PUBLIC_URL \
    MERCURE_JWT_SECRET=$MERCURE_JWT_SECRET \
    JWT_PASSPHRASE=$JWT_PASSPHRASE \
    STRIPE_PK=$STRIPE_PK \
    STRIPE_SK=$STRIPE_SK \
    STRIPE_WH_SK=$STRIPE_WH_SK \
    FRONT_URL=$FRONT_URL \
    KYC_API_URL=$KYC_API_URL \
    KYC_API_SECRET=$KYC_API_SECRET

COPY docker/php/create-dot-env.sh . 
RUN chmod +x create-dot-env.sh; \
	./create-dot-env.sh; \
	rm create-dot-env.sh;

RUN set -eux; \
	mkdir -p var/cache var/log; \
	composer dump-autoload --classmap-authoritative --no-dev; \
	composer dump-env prod; \
	composer run-script --no-dev post-install-cmd; \
	chmod +x bin/console; sync
VOLUME /srv/api/var

COPY docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

COPY docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN php bin/console lexik:jwt:generate-keypair --overwrite --quiet; \
	php bin/console d:m:m --no-interaction --quiet;

ENV SYMFONY_PHPUNIT_VERSION=9

EXPOSE 80
ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]