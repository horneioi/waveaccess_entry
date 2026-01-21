#!/bin/bash
set -e

# Переменные с дефолтами
USER="${NGINX_USER:-admin}"
PASS="${NGINX_PASSWORD:-changeme}"

# Генерируем .htpasswd
mkdir -p /etc/nginx
echo "$USER:$(openssl passwd -apr1 "$PASS")" > /etc/nginx/auth/.htpasswd

# Запуск nginx в форграунд режиме
nginx -g "daemon off;"