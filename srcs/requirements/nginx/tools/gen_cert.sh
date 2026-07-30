#!/bin/bash
set -e

CERT_DIR=/etc/nginx/ssl
mkdir -p "$CERT_DIR"

if [ ! -f "$CERT_DIR/inception.crt" ]; then
    echo "[gen_cert] Generating self-signed certificate for ${DOMAIN_NAME}..."
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout "$CERT_DIR/inception.key" \
        -out "$CERT_DIR/inception.crt" \
        -subj "/C=PT/ST=Braga/L=Braga/O=42/CN=${DOMAIN_NAME}"
fi

echo "[gen_cert] Starting nginx in foreground (PID 1)..."
exec nginx -g "daemon off;"
