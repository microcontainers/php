#!/bin/sh
set -e

export PATH="$COMPOSER_HOME/vendor/bin:$PATH"

if [ "$(id -u)" != 0 ] || [ "${PHP_RUNTIME_CONF-1}" != '1' ]; then
    return
fi

_PHP_INI="$PHP_INI_DIR/php.ini"
for _ENV_NAME in $(printenv | awk -F= '{print $1}'); do
    if [ "${_ENV_NAME:0:8}" = "PHP_EXT_" ]; then
        _PHP_EXT="$(echo "${_ENV_NAME:8}" | tr '[:upper:]' '[:lower:]')"
        _PHP_EXT_FILE="$PHP_INI_DIR/conf.d/${_PHP_EXT}.ini"
        if [ ! -f "$_PHP_EXT_FILE" ] || [ ! -w "$_PHP_EXT_FILE" ]; then
            continue
        fi

        _PHP_VALUE="$(eval echo "\${$_ENV_NAME}")"
        if [ "${_PHP_VALUE}" = 1 ] || [ "${_PHP_VALUE}" = true ]; then
            sed -i "s/^[; ]*\(zend_extension\|extension\)/\1/" "${_PHP_EXT_FILE}"
        else
            sed -i "s/^[; ]*\(zend_extension\|extension\)/;\1/" "${_PHP_EXT_FILE}"
        fi
    elif [ "${_ENV_NAME:0:4}" = "PHP_" ] && [ -w "$_PHP_INI" ]; then
        _PHP_NAME="$(echo "${_ENV_NAME:4}" | sed -e 's|__|\.|g' | tr '[:upper:]' '[:lower:]')"
        _PHP_VALUE="$(eval echo "\${$_ENV_NAME}")"
        if grep "${_PHP_NAME} =" "$_PHP_INI" > /dev/null; then
            sed -i "s|^[; ]*\($_PHP_NAME *=\).*|\1 $_PHP_VALUE|" "$_PHP_INI"
        else
            echo "${_PHP_NAME} = ${_PHP_VALUE}" >> "$_PHP_INI"
        fi
    fi
done

unset -v _PHP_INI _PHP_NAME _PHP_VALUE _ENV_NAME
