#!/bin/bash
set -e

APP_DIR="/app"

# --------------------------------------------------
# Initialize Laravel project if it does not exist.
# --------------------------------------------------
if [ ! -f "$APP_DIR/artisan" ]; then
    TEMP_DIR="$APP_DIR/laravel_temp"
    trap 'rm -rf "$TEMP_DIR"' EXIT
    rm -rf "$TEMP_DIR"

    git config --global --add safe.directory "$APP_DIR"

    composer create-project laravel/laravel "$TEMP_DIR" --prefer-dist

    if [ -d "$APP_DIR/.git" ]; then
        ln -s "$APP_DIR/.git" "$TEMP_DIR/.git"
    fi

    cd "$TEMP_DIR"
    composer require ronasit/laravel-project-initializator --dev -W
    php artisan init "$PROJECT_NAME"

    rm -f "$TEMP_DIR/.git"
    chmod -R 777 "$TEMP_DIR/storage"

    shopt -s dotglob nullglob
    for path in "$TEMP_DIR"/*; do
        name="${path##*/}"

        if [ "$name" = artisan ] || [ "$name" = .git ]; then
            continue
        fi

        rm -rf "${APP_DIR:?}/$name"
        mv "$path" "$APP_DIR"/
    done
    mv "$TEMP_DIR/artisan" "$APP_DIR"/

    cd "$APP_DIR"
    rm -rf "$TEMP_DIR"
fi

# Remove this script after execution
rm -- "$(realpath "${BASH_SOURCE[0]}")"