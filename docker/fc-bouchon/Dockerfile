From ubuntu:xenial
MAINTAINER Alexandre Fenyo <alex@fenyo.net>
EXPOSE 80
ENV TERM vt100
ENV LANG C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN apt-get update && apt-get install -y --allow-downgrades --allow-remove-essential --allow-change-held-packages libterm-ui-perl less zsh vim telnet net-tools git apache2 curl
RUN apt-get install -y --allow-downgrades --allow-remove-essential perl build-essential
RUN echo yes | cpan install URI::Query && cpan install Crypt::JWT
RUN git clone https://github.com/AlexandreFenyo/france-connect.git
RUN mv france-connect/bouchon/* /var/www/html && rm -rf /france-connect
RUN ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load
RUN echo ServerName localhost >> /etc/apache2/apache2.conf
RUN echo "<Directory /var/www/html>" >> /etc/apache2/apache2.conf && echo "Options +ExecCGI" >> /etc/apache2/apache2.conf && echo "AddHandler cgi-script .cgi" >> /etc/apache2/apache2.conf && echo "</Directory>" >> /etc/apache2/apache2.conf
RUN touch /var/log/apache2/access.log /var/log/apache2/error.log
RUN rm /var/www/html/index.html
CMD apachectl start && tail -f /var/log/apache2/*
