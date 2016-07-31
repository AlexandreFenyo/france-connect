From fenyoa/franceconnect-kif
RUN apt-get update && apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages apache2 curl
WORKDIR "/etc/apache2"
CMD rm sites-enabled/000-default.conf && cp -p sites-available/default-ssl.conf sites-enabled && cp -p mods-available/ssl.conf mods-available/ssl.load mod-available/socache_shmcb.load mods-enabled
CMD ["/bin/bash"]
#CMD ["mvn", "tomcat7:run"]

