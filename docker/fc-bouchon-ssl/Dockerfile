From fenyoa/fc-bouchon
MAINTAINER Alexandre Fenyo <alex@fenyo.net>
EXPOSE 443
RUN git clone https://github.com/AlexandreFenyo/france-connect.git
RUN mv france-connect/bouchon/* /var/www/html && rm -rf /france-connect
WORKDIR /etc/apache2
RUN sed -i 's/ServerName localhost/ServerName aws-bouchon.fenyo.net/' apache2.conf
RUN cp -p sites-available/default-ssl.conf sites-enabled && cp -p mods-available/proxy.load mods-available/proxy_ajp.load mods-available/ssl.conf mods-available/ssl.load mods-available/socache_shmcb.load mods-enabled
RUN mv sites-enabled/000-default.conf .
CMD apachectl start && tail -f /var/log/apache2/*
