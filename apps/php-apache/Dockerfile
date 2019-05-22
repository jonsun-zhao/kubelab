FROM php:7-apache

# Generate SSL cert
RUN cd /tmp \
  && openssl req -x509 -newkey rsa:2048 -subj "/C=US/ST=California/L=San Francisco/O=Dis/CN=localhost" -keyout tls.key -out tls.crt -days 3650 -nodes -sha256 \
  && mv ./tls.key /etc/ssl/private/ \
  && mv ./tls.crt /etc/ssl/certs/ \
  && rm -rf /tmp/*

COPY conf/app.conf /etc/apache2/sites-available/
COPY conf/redirect_to_php.conf /etc/apache2/conf-available/
COPY --chown=www-data:www-data src /var/www/html/

RUN a2enmod actions ssl rewrite headers \
  && a2dissite 000-default default-ssl \
  && a2enconf redirect_to_php \
  && a2ensite app

VOLUME /var/www/html/
