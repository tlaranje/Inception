FROM debian:bookworm

RUN apt update && apt upgrade && apt install -y nginx

RUN rm -f /etc/nginx/sites-enabled/default

COPY default /etc/nginx/sites-available/default

RUN ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

CMD ["nginx", "-g", "daemon off;"]