
all:
	@cat Makefile

build-kif:
	@cd kif && docker build -t fenyoa/franceconnect-kif .

push-kif:
	@docker push fenyoa/franceconnect-kif
	

run-kif:
	@docker run -p 80:80 -v ${PWD}/kif/config.properties:/kif/src/main/webapp/META-INF/config.properties -v ${PWD}/kif/log4j.xml:/kif/src/main/resources/log4j.xml -t -i fenyoa/franceconnect-kif
