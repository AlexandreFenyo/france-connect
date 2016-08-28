From fenyoa/franceconnect-kif
RUN apt-get update && apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages apache2 curl
WORKDIR /etc/apache2
RUN rm sites-enabled/000-default.conf && cp -p sites-available/default-ssl.conf sites-enabled && cp -p mods-available/ssl.conf mods-available/ssl.load mods-available/socache_shmcb.load mods-enabled
RUN echo ServerName localhost >> apache2.conf
CMD ["/bin/bash"]
#CMD ["mvn", "tomcat7:run"]

