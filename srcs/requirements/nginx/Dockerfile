FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/gen_cert.sh /usr/local/bin/gen_cert.sh
RUN chmod +x /usr/local/bin/gen_cert.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/gen_cert.sh"]
