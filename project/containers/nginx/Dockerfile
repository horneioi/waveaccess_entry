FROM nginx:latest

COPY config/nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY ./auth/.httpasswd /etc/nginx/.httpasswd
COPY ./certs /etc/nginx/certs
COPY ./root/ /opt/html/root/
COPY ./upload/ /opt/html/upload/

ENTRYPOINT ["/entrypoint.sh"]