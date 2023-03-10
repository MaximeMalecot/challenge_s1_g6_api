#!/bin/sh
set -e

PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-production"
if [ "$APP_ENV" != 'prod' ]; then
	PHP_INI_RECOMMENDED="$PHP_INI_DIR/php.ini-development"
fi
ln -sf "$PHP_INI_RECOMMENDED" "$PHP_INI_DIR/php.ini"

if [ "$APP_ENV" != 'prod' ]; then
	echo "Intalling dependencies..."
	composer install --prefer-dist --no-progress --no-interaction
else
	echo "Warming up cache..."
	php bin/console cache:clear --no-interaction --quiet
fi

if [ ! -d "./config/jwt" ]; then
	echo "Generating jwt keys..."
	php bin/console lexik:jwt:generate-keypair --quiet
fi

if grep -q DB_HOST= .env; then
	echo "Waiting for database to be ready..."
	ATTEMPTS_LEFT_TO_REACH_DATABASE=60
	until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || DATABASE_ERROR=$(php bin/console dbal:run-sql -q "SELECT 1" 2>&1); do
		if [ $? -eq 255 ]; then
			# If the Doctrine command exits with 255, an unrecoverable error occurred
			ATTEMPTS_LEFT_TO_REACH_DATABASE=0
			break
		fi
		sleep 1
		ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
		echo "Still waiting for database to be ready... Or maybe the database is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left."
	done

	if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
		echo "The database is not up or not reachable:"
		echo "$DATABASE_ERROR"
		exit 1
	else
		echo "The database is now ready and reachable"

		if [ "$( find ./migrations -iname '*.php' -print -quit )" ]; then
			echo "Executing migrations..."
			php bin/console doctrine:migrations:migrate --no-interaction --quiet
		fi
		if [ "$APP_ENV" = 'test' ]; then
			echo "Executing fixtures..."
			php bin/console d:f:l --no-interaction --quiet
		fi
	fi
fi

echo "Environnement ready, starting server..."
exec docker-php-entrypoint "$@"
