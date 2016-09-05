
all:
	@cat Makefile

build-kif:
	@cd kif && docker build -t fenyoa/franceconnect-kif .

push-kif:
	@docker push fenyoa/franceconnect-kif

run-kif:
	@docker run -p 80:80 -v ${PWD}/kif/config.properties:/kif/src/main/webapp/META-INF/config.properties -v ${PWD}/kif/log4j.xml:/kif/src/main/resources/log4j.xml -t -i fenyoa/franceconnect-kif

build-bouchon:
	@cd fc-bouchon && docker build -t fenyoa/fc-bouchon .

push-bouchon:
	@docker push fenyoa/fc-bouchon

run-bouchon:
	@docker run -p 8080:80 -t -i fenyoa/fc-bouchon

build-bouchon-ssl:
	@cd fc-bouchon-ssl && docker build -t fenyoa/fc-bouchon-ssl .

run-bouchon-ssl:
	-docker rm bouchon-ssl
	docker run --name bouchon-ssl -p 443:443 -p 80:80 -v ${PWD}/fc-bouchon-ssl/ssl.conf:/etc/apache2/sites-enabled/default-ssl.conf -v ${PWD}/fc-bouchon-ssl/pki:/etc/apache2/pki -t -i fenyoa/fc-bouchon-ssl

build-kif-ssl:
	@cd kif-ssl && docker build -t fenyoa/franceconnect-kif-ssl .

push-kif-ssl:
	@docker push fenyoa/franceconnect-kif-ssl

run-kif-ssl:
	@docker run -p 443:443 -v ${PWD}/kif-ssl/config.properties:/kif/src/main/webapp/META-INF/config.properties -v ${PWD}/kif/log4j.xml:/kif/src/main/resources/log4j.xml -v ${PWD}/kif-ssl/ssl.conf:/etc/apache2/sites-enabled/default-ssl.conf -v ${PWD}/kif-ssl/pki:/etc/apache2/pki -t -i fenyoa/franceconnect-kif-ssl

run-kif-ssl-background:
	@docker run --name kif-ssl -d -p 443:443 -v ${PWD}/kif-ssl/config.properties:/kif/src/main/webapp/META-INF/config.properties -v ${PWD}/kif-ssl/log4j.xml:/kif/src/main/resources/log4j.xml -v ${PWD}/kif-ssl/ssl.conf:/etc/apache2/sites-enabled/default-ssl.conf -v ${PWD}/kif-ssl/pki:/etc/apache2/pki fenyoa/franceconnect-kif-ssl

rm-kif-ssl-background:
	docker stop kif-ssl
	docker rm kif-ssl

