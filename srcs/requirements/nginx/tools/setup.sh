#!/bin/bash

# Check if the self-signed SSL certificate already exists; if not, generate it
if [ ! -f /etc/ssl/certs/nginx-selfsigned.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/C=PT/ST=Porto/L=Porto/O=42/OU=Inception/CN=localhost"
fi

# Start Nginx in the foreground as the container's main process
exec nginx -g "daemon off;"