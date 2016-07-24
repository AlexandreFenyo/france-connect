
# **KIF** : <b>K</b>it d'<b>I</b>ntégration à <b>F</b>ranceConnect

## Introduction

 Ce produit a deux objectifs :

1. **fournir un exemple complet d'implémentation d'un fournisseur [FranceConnect](https://franceconnect.gouv.fr/)** de niveau *production-grade*, largement documenté :
  - en environnement [JEE](http://www.oracle.com/technetwork/java/javaee/overview/index.html), à l'aide du framework [Spring Security](http://projects.spring.io/spring-security/)
  - en s'appuyant sur [MITREid Connect](https://github.com/mitreid-connect/OpenID-Connect-Java-Spring-Server#mitreid-connect), l'implémentation de référence d'[OpenID Connect](http://openid.net/connect/) développée par le [MIT](http://web.mit.edu/)
  - en intégrant le mécanisme de déconnexion, la gestion des niveaux de traces requis et des erreurs

2. **permettre l'intégration facile de l'authentification FranceConnect dans une application existante :**
  -  quelle que soit la technologie utilisée (JEE, Ruby on Rails, Perl/CGI, PHP, Node.js, etc.)
  - en raccordant cette application à l'IdP (*Identity Provider*) interne de KIF, qui se charge d'implémenter la cinématique d'interfaçage avec FranceConnect en se présentant comme un fournisseur de services.

KIF est donc à la fois un POC (*proof of concept*) de fournisseur de services FranceConnect en environnement JEE et un IdP relai entre une application existante (*legacy application*) et l'IdP FranceConnect.

L'implémentation de la fonction POC est dénommée **KIF-SP** (*Service Provider*) et l'implémentation de la fonction relai est dénommée **KIF-IdP** (*Identity Provider*).

## Configuration

### Fichiers de configuration

Deux fichiers de configuration sont utilisés :

- le fichier de configuration des paramètres
- le fichier de configuration des traces

La configuration des paramètres consiste à créer le fichier de paramétrage `config.properties` dans le répertoire `FournisseurDeServices/src/main/webapp/META-INF` à partir du template `config.properties-template` déjà présent dans ce même répertoire.

> :warning:  
> Le démarrage de l'application n'est pas possible avant d'avoir réalisé la configuration des paramètres car le fichier `config.properties` est référencé par le descripteur de déploiement d'application (*web application deployment descriptor*) `web.xml`.  
> **Ce fichier de configuration contient des secrets, il faut donc configurer ses permissions d'accès ainsi que les permissions globales d'accès au système de fichiers sur lequel il est stocké de manière à ce qu'aucune personne non habilitée puisse y accéder.**

La configuration des traces consiste à adapter le fichier `log4j.xml` (format standard [Log4j 1.2.x](http://logging.apache.org/log4j/1.2/)) présent dans le répertoire `FournisseurDeServices/src/main/resources` aux besoins de traces. Dans ce même répertoire, deux exemples sont fournis :

- `log4j-devel.xml` avec un niveau de traces élevé, notamment sur les composants concernés par l'authentification

- `log4j-prod.xml` avec un niveau de trace peu verbeux, intégrant néanmoins toutes les traces nécessaires pour un système en production :
  - conservation des traces de niveau `warn` et supérieurs pour tous les composants
  - conservation des traces de niveau `info` et supérieurs pour KIF, incluant pour chaque événement de création ou suppression de session, d'authentification, d'erreur d'authentification ou de déconnexion (mécanisme de logout global) :
    - l'identifiant de session (valeur du cookie JSESSIONID)
    - la référence à l'objet Java représentant la requête, pour croiser les traces correspondant à une même requête si besoin
    - l'adresse IP du navigateur client
    - le port TCP côté client, pour différencier différents navigateurs présentant une adresse IP commune (cas où l'utilisateur emprunte un proxy ou un réseau NATé, par exemple)
    - la cause d'erreur le cas échéant (jeton invalide, tentative de rejeu, etc.)
    - le nom de la session créée ou détruite le cas échéant
    - le nombre de sessions actives à des fins de *capacity planning* : la mémoire utilisée est une fonction affine du nombre de sessions

### Paramètres de configuration

#### Paramètres pour la fonction KIF-SP (POC de fournisseur de services)

##### Activation de la fonction

- `net.fenyo.franceconnect.config.oidc.debug`

 - type : booléen
 - valeur par défaut : `true` (fonction KIF-SP activée)
 - usage : activation/désactivation de la fonction KIF-SP (POC de fournisseur de service). Positionner la valeur `false` pour le passage en production de la fonction KIF-IdP (IdP relai), afin de désactiver l'exemple de fournisseur de services.

##### Configuration des endpoints

Quatre endpoints sont déclarés pour la configuration de la cinematique d'authentification via FranceConnect : 3 endpoints fournis par FranceConnect et un endpoint pour le fournisseur de service.

- `net.fenyo.franceconnect.config.oidc.authorizationendpointuri`

 - type : URL
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize (valeur utilisée par la plate-forme de développement/intégration de FranceConnect)
 - usage : authorization endpoint de FranceConnect, qui réalise l'authentification de l'utilisateur en le renvoyant vers un fournisseur d'identité FranceConnect et qui fournit en retour un authorization code au fournisseur de services.

- `net.fenyo.franceconnect.config.oidc.tokenendpointuri`

 - type : URL
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr/api/v1/token (valeur utilisée par la plate-forme de développement/intégration de FranceConnect)
 - usage : token endpoint de FranceConnect, contacté directement par le fournisseur de service (invocation d'un web-service REST, donc sans passer par le navigateur de l'utilisateur) pour récupérer, en échange du code d'autorisation, un id token JWT et un access token. La signature de l'id token par FranceConnect est vérifiée par le fournisseur de service. Si cette signature est invalide ou si d'autres éléments de sécurité contenus dans ce jeton sont incorrects, l'authentification est rejetée et un message d'erreur du type suivant est ajouté dans le fichier de traces : `authentication failure exception: [org.springframework.security.authentication.AuthenticationServiceException: ...]`. Dans ce message d'erreur, la chaîne `...` est remplacée par la cause précise du rejet.

- `net.fenyo.franceconnect.config.oidc.userinfoendpointuri`

 - type : URL
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo (valeur utilisée par la plate-forme de développement/intégration de FranceConnect)
 - usage : userinfo endpoint de FranceConnect, contacté directement par le fournisseur de service (invocation d'un web-service REST, donc sans passer par le navigateur de l'utilisateur) pour récupérer, en échange de l'access token, l'identité pivot de l'utilisateur (userinfo) au format JSON.

- `net.fenyo.franceconnect.config.oidc.redirecturi`

 - type : URL
 - valeur par défaut : http://127.0.0.1/openid_connect_login
 - usage : URL du endpoint de callback du fournisseur de services. URL où l'utilisateur est renvoyé après déconnexion du service, qu'il ait accepté ou pas la déconnexion de FranceConnect. **Le choix de la chaîne `openid_connect_login` est imposé par l'implementation MitreID Connect, elle ne doit donc pas être substituée par une autre chaîne**. Cette URL est le endpoint fournisseur de services de MitreID Connect, lui permettant de recevoir le code d'autorisation et d'enchaîner alors la cinématique de récuperation des jetons et de l'identité de l'utilisateur. **Cette URL doit être déclarée par le fournisseur de services sur le [portail de configuration FranceConnect](https://franceconnect.gouv.fr/client/login) dans la section "Urls de callback".**

##### Configuration de la relation de confiance mutuelle avec FranceConnect

- `net.fenyo.franceconnect.config.oidc.clientid`

 - type : chaîne de caractères (représentation hexadécimale d'un nombre de 256 bits)
 - valeur par défaut : aucune
 - usage : client id du fournisseur de services, attribué par FranceConnect sur le [portail d'inscription](https://franceconnect.gouv.fr/inscription). Cet identifiant est public.

- `net.fenyo.franceconnect.config.oidc.clientsecret`

 - type : chaîne de caractères (représentation hexadécimale d'un nombre de 256 bits)
 - valeur par défaut : aucune
 - usage : secret id du fournisseur de services, attribué par FranceConnect sur le [portail d'inscription](https://franceconnect.gouv.fr/inscription). Ce secret partagé ne doit pas être divulgué. Pour cette raison, les droits d'accès au fichier `config.properties` doivent être configurés de telle façon que seul le conteneur d'application puisse accéder à son contenu.

- `net.fenyo.franceconnect.config.oidc.issuer`

 - type : chaîne de caractères
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr (valeur utilisée par la plate-forme de développement/intégration de FranceConnect)
 - usage : identifiant de l'émetteur des token id JWT, attendu dans le claim *iss* de ces jetons.  Si le claim reçu ne correspond pas à la valeur attendue, l'authentification est rejetée et le message d'erreur suivant est ajouté dans le fichier de traces : `authentication failure exception: [org.springframework.security.authentication.AuthenticationServiceException: Issuers do not match]`.

- `net.fenyo.franceconnect.config.oidc.fcbuttonuri`

 - type : URL
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js
 - usage :  URL du code JavaScript du bouton FranceConnect.

##### Configuration du mécanisme de déconnexion

- `net.fenyo.franceconnect.config.oidc.logouturi`

 - type : URL
 - valeur par défaut : https://fcp.integ01.dev-franceconnect.fr/api/v1/logout (valeur utilisée par la plate-forme de développement/intégration de FranceConnect)
 - usage : URL de déconnexion globale (*global logout*). Quand l'utilisateur souhaite se déconnecter du fournisseur de service, ce dernier invalide sa session puis le redirige vers cette URL chez FranceConnect, afin qu'il puisse aussi choisir de se déconnecter de FranceConnect. Il est ensuite redirigé vers le portail du fournisseur de services.

- `net.fenyo.franceconnect.config.oidc.afterlogouturi`

 - type : URL
 - valeur par défaut : http://127.0.0.1/
 - usage : URL où l'utilisateur est renvoyé après déconnexion du service, qu'il ait accepté ou pas la déconnexion de FranceConnect. Cette URL ne pointe pas forcément sur le fournisseur de services, elle peut potentiellement correspondre au site institutionnel associé. Cette URI est aussi utilisée en cas d'erreur d'authentification, pour proposer à l'utilisateur de retourner au site institutionnel. **Cette URL doit être déclarée par le fournisseur de services sur le [portail de configuration FranceConnect](https://franceconnect.gouv.fr/client/login) dans la section "Urls de redirection de déconnexion".**

- `net.fenyo.franceconnect.config.oidc.startlogouturi`

 - type : URL
 - valeur par défaut : j_spring_security_logout
 - usage :  URL de logout utilisée par le bouton FranceConnect ou le fournisseur de service pour initier la séquence de logout.

##### Configuration du comportement du fournisseur de services

- `net.fenyo.franceconnect.config.oidc.sessiontimeout`

 - type : nombre (minutes)
 - valeur par défaut : 240 minutes (4 heures)
 - usage : sans activité pendant ce délai, la session expire donc l'accès à une page protégée nécessite une nouvelle authentification via FranceConnect. Si cette valeur est inférieure à la durée de session de FranceConnect (30 minutes), la reconnexion pourra être transparente dans certains cas.  
   Exemple de séquence de reconnexion transparente :
    - `sessiontimeout` vaut 10 minutes
    - l'utilisateur se connecte au fournisseur de service et s'authentifie via France Connect à t0
    - à partir de t0 + 5 min, l'utilisateur devient inactif
    - sa session chez le fournisseur de service est donc invalide à partir de t0 + 5 min + `sessiontimeout`, c'est-à-dire t0 + 15 min
    - à t0 + 20 min, l'utilisateur reprend son activité en accedant à une page protégée
    - la session ayant expiré, le fournisseur de service renvoie l'utilisateur s'authentifier chez FranceConnect
    - la session FranceConnect n'ayant pas expiré (si l'utilisateur n'a pas réalisé une déconnexion via le bouton FranceConnect entre-temps, depuis ce fournisseur de service ou un autre), FranceConnect fournit un jeton d'autorisation au fournisseur de service sans interaction utilisateur
    - le fournisseur de service utilise ce jeton d'autorisation pour récupérer le token id et l'identité de l'utilisateur

- `net.fenyo.franceconnect.config.oidc.authenticationerroruri`

 - type : URL
 - valeur par défaut : http://127.0.0.1/authenticationError
 - usage :  URL ou l'utilisateur est renvoyé en cas d'erreur d'authentification. Si cette URL pointe vers /authenticationError sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

#### Paramètres pour la fonction KIF-IdP (Identity Provider)

- `net.fenyo.franceconnect.config.idp.key`

 - type : Cle AES 256 bits en hexadecimal (generation via openssl : `openssl rand -hex 32`)
 - valeur par défaut : `a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224`
 - usage :  secret partagé permettant le chiffrement entre l'application à intégrer et KIF-IdP.

- `net.fenyo.franceconnect.config.idp.iv`

 - type : Vecteur d'initialisation 64 bits en hexadecimal (generation via openssl : `openssl rand -hex 16`)
 - valeur par défaut : `87b7225d16ea2ae1f41d0b13fdce9bba`
 - usage :  vecteur d'initialisation nécessaire pour le chiffrement.

Les valeurs par défaut permettent de communiquer avec l'application exemple disponible sur https://fenyo.net/fc/index.cgi

#### Paramètres pour la fonction KIF-SP (POC de fournisseur de services)

### Fichier de paramétrage

Voici un exemple complet de fichier de paramétrage `config.properties` :

````properties
# pour la fonction KIF-FS (POC de fournisseur de services)
net.fenyo.franceconnect.config.oidc.debug=true
net.fenyo.franceconnect.config.oidc.clientid=a100f6923ae93e2e5a8e2e2fb1d0c1e988d8c06c43a8ef838e64eeb932750405
net.fenyo.franceconnect.config.oidc.clientsecret=f7cf2c8cf9863e009c3a520b5f380d9849adad21fe21c0e2782bc9cb25908a67
net.fenyo.franceconnect.config.oidc.sessiontimeout=240
net.fenyo.franceconnect.config.oidc.issuer=https://fcp.integ01.dev-franceconnect.fr
net.fenyo.franceconnect.config.oidc.authorizationendpointuri=https://fcp.integ01.dev-franceconnect.fr/api/v1/authorize
net.fenyo.franceconnect.config.oidc.tokenendpointuri=https://fcp.integ01.dev-franceconnect.fr/api/v1/token
net.fenyo.franceconnect.config.oidc.userinfoendpointuri=https://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo
net.fenyo.franceconnect.config.oidc.redirecturi=http://127.0.0.1/openid_connect_login
net.fenyo.franceconnect.config.oidc.logouturi=https://fcp.integ01.dev-franceconnect.fr/api/v1/logout
net.fenyo.franceconnect.config.oidc.afterlogouturi=http://127.0.0.1/
net.fenyo.franceconnect.config.oidc.authenticationerroruri=http://127.0.0.1/authenticationError
net.fenyo.franceconnect.config.oidc.startlogouturi=j_spring_security_logout
net.fenyo.franceconnect.config.oidc.fcbuttonuri=https://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js
# pour la fonction KIF-IdP (IdP relai)
net.fenyo.franceconnect.config.idp.key=a6a7ee7abe681c9c4cede8e3366a9ded96b92668ea5e26a31a4b0856341ed224
net.fenyo.franceconnect.config.idp.iv=87b7225d16ea2ae1f41d0b13fdce9bba
````

### Traces

#### Choisir où déposer les traces

Voici un exemple complet de fichier de configuration des traces `log4j.xml` pour un serveur en production, les traces étant fournies dans la sortie standard du serveur d'application :

````xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE log4j:configuration PUBLIC "-//APACHE//DTD LOG4J 1.2//EN" "log4j.dtd">
<log4j:configuration xmlns:log4j="http://jakarta.apache.org/log4j/">

	<!-- Appenders -->
	<appender name="console" class="org.apache.log4j.ConsoleAppender">
		<param name="Target" value="System.out" />
		<layout class="org.apache.log4j.PatternLayout">
			<param name="ConversionPattern" value="%-5p: %d %c - %m%n" />
		</layout>
	</appender>
	
	<!-- Application Loggers -->
	<logger name="net.fenyo">
		<level value="info" />
	</logger>

	<!-- Root Logger -->
	<root>
		<priority value="warn" />
		<appender-ref ref="console" />
	</root>
	
</log4j:configuration>
````

Fournir les traces sur la sortie standard du serveur d'application n'est pas toujours le moyen le plus adapté pour les conserver. C'est un moyen idéal dans le cadre d'un serveur d'application hébergé dans un micro-conteneur [Docker](www.docker.com), mais dans le cas contraire, on peut remplacer l'appender de type `ConsoleAppender` pour les stocker plutôt :

- dans un fichier, que l'on fait tourner régulièrement : avec un appender de type [`DailyRollingFileAppender`](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/DailyRollingFileAppender.html)

- sur un serveur SYSLOG centralisé, avec un appender de type [`SyslogAppender`](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/net/SyslogAppender.html)

- dans un fichier d'événements Windows potentiellement rerouté vers un [SIEM](https://fr.wikipedia.org/wiki/Security_information_management_system) comme [LogRhythm](https://logrhythm.com/fr/), avec un appender de type [`NTEventLogAppender`](https://logging.apache.org/log4j/1.2/apidocs/org/apache/log4j/nt/NTEventLogAppender.html)

#### Exploiter les traces

À chaque création de session, une trace correspondante est générée, incluant la valeur du nouvel identifiant de session stocké dans le cookie JSESSIONID et une mise à jour du nombre de sessions en mémoire :
````
INFO : 2016-07-24 03:25:16,203 net.fenyo.franceconnect.SessionListener - log fc: msg [création de session 2236652D2F06E535395CDA6CA557B9BF (21 sessions)]; auth: oidc authentication token is null; req: request attributes are null
````

À chaque invalidation de session, une trace correspondante est générée, incluant l'identifiant de session supprimé, l'identité de l'utilisateur concerné et une mise à jour du nombre de sessions en mémoire (il n'y a pas d'origine de requête car la session peut être supprimée par l'expiration du timeout de sessions, sans action utilisateur) :

Exemple de session supprimée à l'expiration du timeout de session :
````
INFO : 2016-07-24 04:21:14,525 net.fenyo.franceconnect.SessionListener - log fc: msg [destruction de session 2236652D2F06E535395CDA6CA557B9BF (20 session)]; auth: id token [eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNTRmNzBhNTU3ZDgzOGJjZDI2YWJkMjIwMzgxMjY4MTkyOTllZjIwNDhjMDFlYWI5N2E3YTEwNTQ1OTc2ZWY5OHYxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2OTMyMDg2NCwiaWF0IjoxNDY5MzE5NjY0LCJub25jZSI6IjE5NzQzYTM2YzQ0YzgiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.rqqL1WrCaDZAwq4fs8uzt17DMY75L4nffjgr6f51cSY]; auth: user info [{"sub":"54f70a557d838bcd26abd22038126819299ef2048c01eab97a7a10545976ef98v1","gender":"male","birthdate":"1981-06-23","birthcountry":"99100","birthplace":"91272","given_name":"Eric","family_name":"Mercier","email":"eric.mercier@france.fr","address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}}]; req: request attributes are null
````

Exemple de session supprimée à la demande d'un utilisateur (l'adresse IP et le port TCP d'origine de la requête sont fournis dans la trace *logout* qui suit la trace *destruction de session* ; ces deux traces peuvent être croisées car elles disposent toutes deux du même identifiant de session 2236652D2F06E535395CDA6CA557B9BF) :
````
INFO : 2016-07-24 03:36:56,092 net.fenyo.franceconnect.SessionListener - log fc: msg [destruction de session 2236652D2F06E535395CDA6CA557B9BF (20 sessions)]; auth: id token [eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNTRmNzBhNTU3ZDgzOGJjZDI2YWJkMjIwMzgxMjY4MTkyOTllZjIwNDhjMDFlYWI5N2E3YTEwNTQ1OTc2ZWY5OHYxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2OTMyNDczMiwiaWF0IjoxNDY5MzIzNTMyLCJub25jZSI6IjEwMjY0YTBmODAyYmQiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.RfOvGXAfDm4UvH1XGIVeVe-_0JDZVuLdzTAyGi8n5io]; auth: user info [{"sub":"54f70a557d838bcd26abd22038126819299ef2048c01eab97a7a10545976ef98v1","gender":"male","birthdate":"1981-06-23","birthcountry":"99100","birthplace":"91272","given_name":"Eric","family_name":"Mercier","email":"eric.mercier@france.fr","address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}}]; req: request attributes are null
INFO : 2016-07-24 03:36:56,095 net.fenyo.franceconnect.LogoutHandler - log fc: msg [logout]; auth: id token [eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNTRmNzBhNTU3ZDgzOGJjZDI2YWJkMjIwMzgxMjY4MTkyOTllZjIwNDhjMDFlYWI5N2E3YTEwNTQ1OTc2ZWY5OHYxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2OTMyNDczMiwiaWF0IjoxNDY5MzIzNTMyLCJub25jZSI6IjEwMjY0YTBmODAyYmQiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.RfOvGXAfDm4UvH1XGIVeVe-_0JDZVuLdzTAyGi8n5io]; auth: user info [{"sub":"54f70a557d838bcd26abd22038126819299ef2048c01eab97a7a10545976ef98v1","gender":"male","birthdate":"1981-06-23","birthcountry":"99100","birthplace":"91272","given_name":"Eric","family_name":"Mercier","email":"eric.mercier@france.fr","address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}}]; req: session id [2236652D2F06E535395CDA6CA557B9BF]; req: remote addr [127.0.0.1]; req: remote port [62437]; req: request [org.springframework.security.web.context.HttpSessionSecurityContextRepository$Servlet3SaveToSessionRequestWrapper@1f59c634]
````

À chaque accès à une ressource protégée, une trace correspondante est générée, incluant notamment l'identité de l'utilisateur, l'identifiant de session, une référence à la requête, l'adresse IP et le port d'origine de la requête :
````
INFO : 2016-07-24 03:25:33,139 net.fenyo.franceconnect.WebController - log fc: msg [accès à /user]; auth: id token [eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJodHRwczovL2ZjcC5pbnRlZzAxLmRldi1mcmFuY2Vjb25uZWN0LmZyIiwic3ViIjoiNTRmNzBhNTU3ZDgzOGJjZDI2YWJkMjIwMzgxMjY4MTkyOTllZjIwNDhjMDFlYWI5N2E3YTEwNTQ1OTc2ZWY5OHYxIiwiYXVkIjoiOWViZjFhZDkwODQyMDdjNWU0OTM5YmNjNmM3NThjODBmMjYwZWU3MDE3N2E0MjRlOTQ3NTRiZWNlZmNiNDU3ZSIsImV4cCI6MTQ2OTMyNDczMiwiaWF0IjoxNDY5MzIzNTMyLCJub25jZSI6IjEwMjY0YTBmODAyYmQiLCJpZHAiOiJGQyIsImFjciI6ImVpZGFzMiIsImFtciI6W119.RfOvGXAfDm4UvH1XGIVeVe-_0JDZVuLdzTAyGi8n5io]; auth: user info [{"sub":"54f70a557d838bcd26abd22038126819299ef2048c01eab97a7a10545976ef98v1","gender":"male","birthdate":"1981-06-23","birthcountry":"99100","birthplace":"91272","given_name":"Eric","family_name":"Mercier","email":"eric.mercier@france.fr","address":{"formatted":"26 rue Desaix, 75015 Paris","street_address":"26 rue Desaix","locality":"Paris","region":"Ile-de-France","postal_code":"75015","country":"France"}}]; req: session id [2236652D2F06E535395CDA6CA557B9BF]; req: remote addr [127.0.0.1]; req: remote port [62375]; req: request [SecurityContextHolderAwareRequestWrapper[ org.springframework.security.web.savedrequest.SavedRequestAwareWrapper@44f3efb7]]
````

Lors qu'une erreur d'authentification se produit, une trace correspondante est générée :
````
INFO : 2016-07-24 03:47:24,138 net.fenyo.franceconnect.AuthenticationFailureHandler - log fc: msg [authentication failure exception: [org.springframework.security.authentication.AuthenticationServiceException: State parameter mismatch on return. Expected null got 205775549532c]]; auth: oidc authentication token is null; req: session id [null]; req: remote addr [127.0.0.1]; req: remote port [62535]; req: request [org.springframework.security.web.context.HttpSessionSecurityContextRepository$Servlet3SaveToSessionRequestWrapper@4216b2a1]
````




## Cinématique d'authentification

La cinématique d'authentification est constituée des étapes suivantes :

1. Lorsque le filtre Spring MitreID Connect détecte l'accès a une ressource protégée et qu'il n'y a pas eu de précédente authentification pour la session courante,  MitreID Connect redirige alors l'utilisateur vers son endpoint de callback.
2. Ce endpoint constate qu'aucun id token n'est associé à cette session et qu'aucun paramètre contenant un code d'autorisation n'est fourni dans la requête qu'il reçoit.
3. Il entame donc la cinématique OpenID Connect pour demander un code d'autorisation à l'authorization endpoint et ce code est renvoyé par FranceConnect sur ce endpoint.
4. À la reception du code, le endpoint de callback invoque alors un web services REST vers le token endpoint de FranceConnect pour récuperer un id token et un access token.
5. Un nouveau web service REST présentant l'access token est invoqué sur le userinfo endpoint de FranceConnect pour récupérer le userinfo qui représente l'identité de l'utilisateur au format JSON.
6. L'utilisateur est enfin renvoyé vers la ressource protégée, à laquelle il a désormais accès.

Ce diagramme de séquence UML présente l'ensemble des échanges en jeu dans cette phase d'authentification entre les différents acteurs (navigateur, fournisseur de services, FranceConnect, fournisseur d'identité) :

![authentification - diagramme de séquence UML](docs/authentification1.png "authentification - diagramme de séquence UML")

## Cinématique de déconnexion

**La cinématique de déconnexion n'est pas spécifiée dans le protocole OpenID Connect**, mais directement par FranceConnect. C'est pour cela que l'on n'évoque pas ici des endpoints mais simplement des URL de logout et de post-logout. N'étant pas une cinématique normée, elle n'est pas implémentée par MitreID Connect et a donc dû être développée spécifiquement dans KIF-SP.

La cinématique de déconnexion est constituée des étapes suivantes :

1. Lorsque l'utilisateur clique sur le lien de déconnexion dans le bouton FranceConnect ou via un lien d'une page du fournisseur de services, son navigateur effectue une requête GET sur l'URL de logout du fournisseur de services.
2. Le contrôleur Spring MVC invalide alors la session et redirige le navigateur vers l'URL de logout de FranceConnect.
3. FranceConnect propose à l'utilisateur de se déconnecter de FranceConnect, ou de rester connecté.
4. Selon le choix de l'utilisateur, FranceConnect invalide éventuellement la session utilisateur et, dans tous les cas, redirige son navigateur vers l'URL post-logout du fournisseur de services.
5. Le fournisseur de services fournit la page HTML correspondant à son URL post-logout.

Ce diagramme de séquence UML présente l'ensemble des échanges en jeu dans cette phase de déconnexion où interviennent le navigateur, le fournisseur de services et FranceConnect (le fournisseur d'identité n'est pas concerné) :

![déconnexion - diagramme de séquence UML](docs/deconnexion1.png "déconnexion - diagramme de séquence UML")


----------

à rédiger :
KIF :
composition du package
licence
glossaire

KIF-SP :
description fonctionnelle : les pages, les protections
protéger une page
configuration
lancement
migration en production
traces
performances
déconnexion
fonctionnement interne

KIT-IdP :
configuration
lancement
tâches de migration en production
fonctionnement interne







````
INFO : 2016-07-23 01:13:40,172 net.fenyo.franceconnect.AuthenticationFailureHandler - log fc: msg [authentication failure exception: [org.springframework.security.authentication.AuthenticationServiceException: Issuers do not match, expected https://fcp.integ01.dev-franceconnect.com got https://fcp.integ01.dev-franceconnect.fr]]; auth: oidc authentication token is null; req: session id [E5C557D3C52E05C8967960454D75DB51]; req: remote addr [127.0.0.1]; req: remote port [51619]; req: request [org.springframework.security.web.context.HttpSessionSecurityContextRepository$Servlet3SaveToSessionRequestWrapper@48697e93]
````



----------

aller directement à un lien : [stack edit](#welcome-to-stackedit)

<font color="red">ou directment du html</h1>

https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet
https://help.github.com/articles/basic-writing-and-formatting-syntax/
# The largest heading
## The second largest heading
### troisième
#### 4ième
###### The smallest heading

**bold and *italic* and bold**

> ceci est retrait

Le code comme `telnet`peut être quoté en ligne ou en bloc :
```java
public String GetComment(final String str) {
}
```

Un lien vers la page de l'[auteur](http://fenyo.net)
Ou directement : http://fenyo.net

Il y a des listes :

- de choses
- et d'autres

Mais on peut aussi numéroter :

1. ceci est le niveau 2
  1. :arrows_counterclockwise: et ceci le niveau 2
  2. :arrows_counterclockwise:
  - et sous liste

:arrows_counterclockwise: intéressant

http://www.webpagefx.com/tools/emoji-cheat-sheet/

on peut faire des lignes qui se suivent.
Par exemple comme ceci.




----------


Welcome to StackEdit!
===================


Hey! I'm your first Markdown document in **StackEdit**[^stackedit]. Don't delete me, I'm very helpful! I can be recovered anyway in the **Utils** tab of the <i class="icon-cog"></i> **Settings** dialog.

----------


Documents
-------------

StackEdit stores your documents in your browser, which means all your documents are automatically saved locally and are accessible **offline!**

> **Note:**

> - StackEdit is accessible offline after the application has been loaded for the first time.
> - Your local documents are not shared between different browsers or computers.
> - Clearing your browser's data may **delete all your local documents!** Make sure your documents are synchronized with **Google Drive** or **Dropbox** (check out the [<i class="icon-refresh"></i> Synchronization](#synchronization) section).

#### <i class="icon-file"></i> Create a document

The document panel is accessible using the <i class="icon-folder-open"></i> button in the navigation bar. You can create a new document by clicking <i class="icon-file"></i> **New document** in the document panel.

#### <i class="icon-folder-open"></i> Switch to another document

All your local documents are listed in the document panel. You can switch from one to another by clicking a document in the list or you can toggle documents using <kbd>Ctrl+[</kbd> and <kbd>Ctrl+]</kbd>.

#### <i class="icon-pencil"></i> Rename a document

You can rename the current document by clicking the document title in the navigation bar.

#### <i class="icon-trash"></i> Delete a document

You can delete the current document by clicking <i class="icon-trash"></i> **Delete document** in the document panel.

#### <i class="icon-hdd"></i> Export a document

You can save the current document to a file by clicking <i class="icon-hdd"></i> **Export to disk** from the <i class="icon-provider-stackedit"></i> menu panel.

> **Tip:** Check out the [<i class="icon-upload"></i> Publish a document](#publish-a-document) section for a description of the different output formats.


----------


Synchronization
-------------------

StackEdit can be combined with <i class="icon-provider-gdrive"></i> **Google Drive** and <i class="icon-provider-dropbox"></i> **Dropbox** to have your documents saved in the *Cloud*. The synchronization mechanism takes care of uploading your modifications or downloading the latest version of your documents.

> **Note:**

> - Full access to **Google Drive** or **Dropbox** is required to be able to import any document in StackEdit. Permission restrictions can be configured in the settings.
> - Imported documents are downloaded in your browser and are not transmitted to a server.
> - If you experience problems saving your documents on Google Drive, check and optionally disable browser extensions, such as Disconnect.

#### <i class="icon-refresh"></i> Open a document

You can open a document from <i class="icon-provider-gdrive"></i> **Google Drive** or the <i class="icon-provider-dropbox"></i> **Dropbox** by opening the <i class="icon-refresh"></i> **Synchronize** sub-menu and by clicking **Open from...**. Once opened, any modification in your document will be automatically synchronized with the file in your **Google Drive** / **Dropbox** account.

#### <i class="icon-refresh"></i> Save a document

You can save any document by opening the <i class="icon-refresh"></i> **Synchronize** sub-menu and by clicking **Save on...**. Even if your document is already synchronized with **Google Drive** or **Dropbox**, you can export it to a another location. StackEdit can synchronize one document with multiple locations and accounts.

#### <i class="icon-refresh"></i> Synchronize a document

Once your document is linked to a <i class="icon-provider-gdrive"></i> **Google Drive** or a <i class="icon-provider-dropbox"></i> **Dropbox** file, StackEdit will periodically (every 3 minutes) synchronize it by downloading/uploading any modification. A merge will be performed if necessary and conflicts will be detected.

If you just have modified your document and you want to force the synchronization, click the <i class="icon-refresh"></i> button in the navigation bar.

> **Note:** The <i class="icon-refresh"></i> button is disabled when you have no document to synchronize.

#### <i class="icon-refresh"></i> Manage document synchronization

Since one document can be synchronized with multiple locations, you can list and manage synchronized locations by clicking <i class="icon-refresh"></i> **Manage synchronization** in the <i class="icon-refresh"></i> **Synchronize** sub-menu. This will let you remove synchronization locations that are associated to your document.

> **Note:** If you delete the file from **Google Drive** or from **Dropbox**, the document will no longer be synchronized with that location.

----------


Publication
-------------

Once you are happy with your document, you can publish it on different websites directly from StackEdit. As for now, StackEdit can publish on **Blogger**, **Dropbox**, **Gist**, **GitHub**, **Google Drive**, **Tumblr**, **WordPress** and on any SSH server.

#### <i class="icon-upload"></i> Publish a document

You can publish your document by opening the <i class="icon-upload"></i> **Publish** sub-menu and by choosing a website. In the dialog box, you can choose the publication format:

- Markdown, to publish the Markdown text on a website that can interpret it (**GitHub** for instance),
- HTML, to publish the document converted into HTML (on a blog for example),
- Template, to have a full control of the output.

> **Note:** The default template is a simple webpage wrapping your document in HTML format. You can customize it in the **Advanced** tab of the <i class="icon-cog"></i> **Settings** dialog.

#### <i class="icon-upload"></i> Update a publication

After publishing, StackEdit will keep your document linked to that publication which makes it easy for you to update it. Once you have modified your document and you want to update your publication, click on the <i class="icon-upload"></i> button in the navigation bar.

> **Note:** The <i class="icon-upload"></i> button is disabled when your document has not been published yet.

#### <i class="icon-upload"></i> Manage document publication

Since one document can be published on multiple locations, you can list and manage publish locations by clicking <i class="icon-upload"></i> **Manage publication** in the <i class="icon-provider-stackedit"></i> menu panel. This will let you remove publication locations that are associated to your document.

> **Note:** If the file has been removed from the website or the blog, the document will no longer be published on that location.

----------


Markdown Extra
--------------------

StackEdit supports **Markdown Extra**, which extends **Markdown** syntax with some nice features.

> **Tip:** You can disable any **Markdown Extra** feature in the **Extensions** tab of the <i class="icon-cog"></i> **Settings** dialog.

> **Note:** You can find more information about **Markdown** syntax [here][2] and **Markdown Extra** extension [here][3].


### Tables

**Markdown Extra** has a special syntax for tables:

Item     | Value
-------- | ---
Computer | $1600
Phone    | $12
Pipe     | $1

You can specify column alignment with one or two colons:

| Item     | Value | Qty   |
| :------- | ----: | :---: |
| Computer | $1600 |  5    |
| Phone    | $12   |  12   |
| Pipe     | $1    |  234  |


### Definition Lists

**Markdown Extra** has a special syntax for definition lists too:

Term 1
Term 2
:   Definition A
:   Definition B

Term 3

:   Definition C

:   Definition D

	> part of definition D


### Fenced code blocks

GitHub's fenced code blocks are also supported with **Highlight.js** syntax highlighting:

```
// Foo
var bar = 0;
```

> **Tip:** To use **Prettify** instead of **Highlight.js**, just configure the **Markdown Extra** extension in the <i class="icon-cog"></i> **Settings** dialog.

> **Note:** You can find more information:

> - about **Prettify** syntax highlighting [here][5],
> - about **Highlight.js** syntax highlighting [here][6].


### Footnotes

You can create footnotes like this[^footnote].

  [^footnote]: Here is the *text* of the **footnote**.


### SmartyPants

SmartyPants converts ASCII punctuation characters into "smart" typographic punctuation HTML entities. For example:

|                  | ASCII                        | HTML              |
 ----------------- | ---------------------------- | ------------------
| Single backticks | `'Isn't this fun?'`            | 'Isn't this fun?' |
| Quotes           | `"Isn't this fun?"`            | "Isn't this fun?" |
| Dashes           | `-- is en-dash, --- is em-dash` | -- is en-dash, --- is em-dash |


### Table of contents

You can insert a table of contents using the marker `[TOC]`:

[TOC]


### MathJax

You can render *LaTeX* mathematical expressions using **MathJax**, as on [math.stackexchange.com][1]:

The *Gamma function* satisfying $\Gamma(n) = (n-1)!\quad\forall n\in\mathbb N$ is via the Euler integral

$$
\Gamma(z) = \int_0^\infty t^{z-1}e^{-t}dt\,.
$$

> **Tip:** To make sure mathematical expressions are rendered properly on your website, include **MathJax** into your template:

```
<script type="text/javascript" src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML"></script>
```

> **Note:** You can find more information about **LaTeX** mathematical expressions [here][4].

```sequence
navigateur->fournisseur de services: GET sur URL de logout\nhttp://127.0.0.1/j_spring_security_logout
Note right of fournisseur de services: le fournisseur invalide la session
fournisseur de services-->navigateur: redirection vers URL de déconnexion de FranceConnect

navigateur->FranceConnect: GET sur URL de déconnexion de FranceConnect\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/logout?id_token_hint=...
FranceConnect-->navigateur: fourniture de la page HTML proposant la déconnexion de FranceConnect

navigateur->FranceConnect: POST sur URL de déconnexion de FranceConnect avec le choix utilisateur\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/logout?id_token_hint=...
Note right of FranceConnect: invalidation de la session FranceConnect\nsi l'utilisateur a fait ce choix
FranceConnect-->navigateur: redirection vers URL post-logout du fournisseur de services

navigateur->fournisseur de services: GET sur URL de post-logout\nhttp://127.0.0.1/
fournisseur de services-->navigateur: fourniture de la page HTML post-logout
```

### UML diagrams

```sequence
navigateur->fournisseur de services: GET sur ressource protégée par Spring Security\nhttp://127.0.0.1/user
fournisseur de services-->navigateur: redirection vers callback endpoint fournisseur

navigateur->fournisseur de services: GET sur callback endpoint fournisseur\nhttp://127.0.0.1/openid_connect_login?...
fournisseur de services-->navigateur: redirection vers authorization endpoint FranceConnect

navigateur->FranceConnect: GET sur authorization endpoint FranceConnect\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?response_type=code&client_id=...
FranceConnect-->navigateur: redirection vers page de sélection d'un fournisseur d'identité

navigateur->FranceConnect: GET de la page permettant de choisir un fournisseur d'identité
FranceConnect-->navigateur: page contenant la liste des fournisseurs d'identité et une URL d'accès pour chacun d'eux

navigateur->FranceConnect: GET sur URL d'accès au fournisseur d'identité choisi par l'utilisateur\nhttps://fcp.integ01.dev-franceconnect.fr/call?provider=dgfip
FranceConnect-->navigateur: redirection vers authorization endpoint du fournisseur d'identité

navigateur->fournisseur d'identité: GET sur authorization endpoint du fournisseur d'identité\nhttps://fip1.integ01.dev-franceconnect.fr/user/authorize?state=...
fournisseur d'identité-->navigateur: redirection vers formulaire d'authentification

navigateur->fournisseur d'identité: GET sur formulaire d'authentification pour connaître son contenu et l'afficher à l'utilisateur\nhttps://fip1.integ01.dev-franceconnect.fr/my/login?...
fournisseur d'identité-->navigateur: fourniture de la page HTML du formulaire

navigateur->fournisseur d'identité: POST sur formulaire d'authentification avec l'identifiant et le mot de passe utilisateur\nhttps://fip1.integ01.dev-franceconnect.fr/my/login?...
fournisseur d'identité-->navigateur: redirection vers authorization endpoint du fournisseur d'identité pour obtenir un code d'autorisation

navigateur->fournisseur d'identité: GET sur authorization endpoint du fournisseur d'identité pour obtenir un code d'autorisation\nhttps://fip1.integ01.dev-franceconnect.fr/user/authorize?response_type=code&client_id=...
fournisseur d'identité-->navigateur: redirection vers callback endpoint FranceConnect pour lui fournir le code d'autorisation

navigateur->FranceConnect: GET sur callback endpoint avec le code d'autorisation\nhttps://fcp.integ01.dev-franceconnect.fr/oidc_callback?code=...

FranceConnect->fournisseur d'identité: web service REST : fourniture du code d'autorisation\n(URL du token endpoint)
fournisseur d'identité-->FranceConnect: renvoi d'un token id JWT et d'un token access
FranceConnect->fournisseur d'identité: web service REST : fourniture du token access\n(URL du userinfo endpoint)
fournisseur d'identité-->FranceConnect: renvoi de l'identité utilisateur (format JSON)
FranceConnect-->navigateur: redirection vers authorization endpoint

navigateur->FranceConnect: GET sur authorization endpoint FranceConnect\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/authorize?...
FranceConnect-->navigateur: fourniture de la page HTML présentant l'identité utilisateur et la demande\nd'autorisation de renvoi de ces informations au fournisseur de service

navigateur->FranceConnect: POST pour accepter de fournir l'identité au fournisseur de services\nhttps://fcp.integ01.dev-franceconnect.fr/confirm-redirect-client
FranceConnect-->navigateur: redirection vers callback endpoint du fournisseur de services\npour lui fournir le code d'autorisation

navigateur->fournisseur de services: GET sur callback endpoint pour lui fournir le code d'autorisation\nhttp://127.0.0.1/openid_connect_login?code=...

fournisseur de services->FranceConnect: web service REST : fourniture du code d'autorisation\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/token
FranceConnect-->fournisseur de services: renvoi d'un token id JWT et d'un token access
fournisseur de services->FranceConnect: web service REST : fourniture du token access\nhttps://fcp.integ01.dev-franceconnect.fr/api/v1/userinfo
FranceConnect-->fournisseur de services: renvoi de l'identité utilisateur (format JSON)
fournisseur de services-->navigateur: redirection vers ressource protégée

navigateur->fournisseur de services: GET sur ressource protégée par Spring Security\nhttp://127.0.0.1/user
fournisseur de services-->navigateur: contenu de la ressource protégée
```


You can also render sequence diagrams like this:

```sequence
Alice->Bob: Hello Bob, how are you?
Note right of Bob: Bob thinks
Bob-->Alice: I am good thanks!
```

And flow charts like this:

```flow
st=>start: Start
e=>end
op=>operation: My Operation
cond=>condition: Yes or No?

st->op->cond
cond(yes)->e
cond(no)->op
```

> **Note:** You can find more information:

> - about **Sequence diagrams** syntax [here][7],
> - about **Flow charts** syntax [here][8].

### Support StackEdit

[![](https://cdn.monetizejs.com/resources/button-32.png)](https://monetizejs.com/authorize?client_id=ESTHdCYOi18iLhhO&summary=true)

[StackEdit](https://stackedit.io/) is a full-featured, open-source Markdown editor based on PageDown, the Markdown library used by Stack Overflow and the other Stack Exchange sites.


  [1]: http://math.stackexchange.com/
  [2]: http://daringfireball.net/projects/markdown/syntax "Markdown"
  [3]: https://github.com/jmcmanus/pagedown-extra "Pagedown Extra"
  [4]: http://meta.math.stackexchange.com/questions/5020/mathjax-basic-tutorial-and-quick-reference
  [5]: https://code.google.com/p/google-code-prettify/
  [6]: http://highlightjs.org/
  [7]: http://bramp.github.io/js-sequence-diagrams/
  [8]: http://adrai.github.io/flowchart.js/

