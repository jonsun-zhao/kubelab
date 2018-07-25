FROM nginx:latest

# Generate SSL cert
RUN apt-get update \
    && apt-get -y install openssl \
    && cd /tmp \
    && openssl req -x509 -newkey rsa:2048 -subj "/C=US/ST=California/L=San Francisco/O=Dis/CN=localhost" -keyout tls.key -out tls.crt -days 3650 -nodes -sha256 \
    && mv ./tls.key /etc/nginx/conf.d/ \
    && mv ./tls.crt /etc/nginx/conf.d/ \
    && rm -rf /tmp/*

COPY conf/* /etc/nginx/conf.d/
COPY src/* /usr/share/nginx/html/

VOLUME /usr/share/nginx/html

EXPOSE 80 443
