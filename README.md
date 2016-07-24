
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

 - type : Vecteur d'initialisation 128 bits en hexadecimal (generation via openssl : `openssl rand -hex 16`)
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

### Configuration des traces

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

## Exploitation des traces

### Format des traces

#### Traces d'informations

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

#### Traces d'erreurs

Lorsqu'une erreur liée à l'authentification se produit, une trace correspondante est générée :
````
INFO : 2016-07-24 03:47:24,138 net.fenyo.franceconnect.AuthenticationFailureHandler - log fc: msg [authentication failure exception: [org.springframework.security.authentication.AuthenticationServiceException: State parameter mismatch on return. Expected null got 205775549532c]]; auth: oidc authentication token is null; req: session id [null]; req: remote addr [127.0.0.1]; req: remote port [62535]; req: request [org.springframework.security.web.context.HttpSessionSecurityContextRepository$Servlet3SaveToSessionRequestWrapper@4216b2a1]
````

### Gestion des erreurs

#### Phase d'authentification

##### Comportement attendu

Le comportement standard de MitreID Connect, en cas d'erreur d'authentification, consiste à indiquer au navigateur une erreur de type 401, incluant un descriptif de la cause de l'erreur. Dans KIF, ce comportement a été remplacé par la bonne pratique de sécurité consistant à cacher les précisions concernant la cause de l'erreur d'authentification. La cause de l'erreur est tracée et l'utilisateur est renvoyé vers un page d'erreur générique configurable par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`.

##### Session expirée

Si la session a expiré entre l'envoi vers FranceConnect et le retour avec le code d'autorisation, alors une [trace d'erreur](#traces-derreurs) est générée avec le message suivant : "Authentication Failed: State parameter mismatch on return. Expected null got 2f3e7b5c97c0c". La valeur null indique que l'état associé à la session (paramètre `state` dans le protocole OpenID Connect) n'a pas pu être trouvé car il n'y a pas de session ou que cette session n'a jamais tenté de se connecter via FranceConnect. L'utilisateur est alors redirigé vers la page d'erreur définie par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`. Si la valeur de ce paramètre est une URL qui pointe vers `/authenticationError` sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par la valeur du paramètre `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

##### &Eacute;tat invalide

Si l'état (paramètre `state` dans le protocole OpenID Connect) ne correspond pas à celui envoyé à FranceConnect dans le cadre de l'authentification de cette session, alors une [trace d'erreur](#traces-derreurs) est générée avec le message suivant : `Authentication Failed: State parameter mismatch on return. Expected 3f3222875114b got 2f3e7b5c97c0c`. La valeur attendue (3f3222875114b) est celle de l'état envoyé à France Connect et le faux état reçu est 2f3e7b5c97c0c. L'utilisateur est alors redirigé vers la page d'erreur définie par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`. Si la valeur de ce paramètre est une URL qui pointe vers `/authenticationError` sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par la valeur du paramètre `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

##### Code d'autorisation invalide

Si le code d'autorisation utilisé est faux ou a déjà été utilisé, alors l'échange suivant se produit avec FranceConnect :

- le fournisseur de service émet la requête suivante au token endpoint de France Connect :
````http
POST /api/v1/token HTTP/1.1
Accept: text/plain, application/json, application/*+json, */*
Content-Type: application/x-www-form-urlencoded
Content-Length: 312
Host: fcp.integ01.dev-franceconnect.fr
Accept-Encoding: gzip,deflate

grant_type=authorization_code&code=1660c04e70db2b5311e6a7ab80c19246c3b7f123354d48c05f40d2aac3fb6c7c&redirect_uri=http%3A%2F%2F127.0.0.1%2Fopenid_connect_login&client_id=CLIENT_ID&client_secret=SECRET_ID
````

- FranceConnect signale que le code est invalide :
````http
HTTP/1.1 400 Bad Request
Server: nginx
Date: Wed, 20 Jul 2016 17:09:24 GMT
Content-Type: application/json; charset=utf-8
Content-Length: 27
Connection: keep-alive
ETag: W/"1b-BTGn9J/xQNk2eWB3zdcJSA"
Vary: Accept-Encoding
````

- Une [trace d'erreur](#traces-derreurs) est générée avec le message suivant : `Authentication Failed: Unable to obtain Access Token: 400 Bad Request`. L'utilisateur est alors redirigé vers la page d'erreur définie par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`. Si la valeur de ce paramètre est une URL qui pointe vers `/authenticationError` sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par la valeur du paramètre `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

##### Nonce invalide

Si le nonce reçu n'est pas celui attendu, une Une trace d'erreur](#traces-derreurs) est générée avec un message indiquant une possible tentative d'attaque par *replay*. L'utilisateur est alors redirigé vers la page d'erreur définie par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`. Si la valeur de ce paramètre est une URL qui pointe vers `/authenticationError` sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par la valeur du paramètre `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

##### Autres cas d'erreur d'authentification

De nombreuses vérifications de sécurité sont imposées par le protocole OpenID Connect, par exemple la vérification de la signature des token id JWT. Si une de ces vérifications conduit à une erreur, une [trace d'erreur](#traces-derreurs) est générée avec un message décrivant la raison de cette erreur. L'utilisateur est alors redirigé vers la page d'erreur définie par le paramètre de configuration `net.fenyo.franceconnect.config.oidc.authenticationerroruri`. Si la valeur de ce paramètre est une URL qui pointe vers `/authenticationError` sur le fournisseur de service, l'utilisateur se verra alors proposé de continuer sa navigation sur l'URL définie par la valeur du paramètre `net.fenyo.franceconnect.config.oidc.afterlogouturi`.

#### Phase de logout

Au moment d'une tentative de déconnexion, si la session a déjà expiré ou si une déconnexion s'est déjà produite, le fournisseur de services redirige le navigateur vers l'URL configurée après déconnexion sans passer par FranceConnect puisqu'il ne dispose plus d'id token à lui indiquer. Ce cas se produit par exemple si deux onglets sont ouverts sur l'application et sont connectés via la même session, et que l'un des onglets a réalisé une déconnexion via le bouton FranceConnect. Si une déconnexion est alors initiée par le bouton FranceConnect du second onglet, il n'y a pas de contexte d'authentification, donc on ne peut ni ne doit renvoyer vers FranceConnect pour une déconnexion.

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

## Intégration de MitreID Connect dans Spring

MitreID Connect est un filtre de sécurité [Spring Security](http://projects.spring.io/spring-security/). L'intégration de l'authentification OpenID Connect dans KIF-SP a donc consisté à configurer [Spring MVC](http://docs.spring.io/spring/docs/current/spring-framework-reference/html/mvc.html) pour s'appuyer sur [Spring Security](http://projects.spring.io/spring-security/) afin de protéger les ressources et à configurer un filtre [Spring Security](http://projects.spring.io/spring-security/) à l'aide de MitreID Connect.

Cette configuration a été mise en place dans le fichier décrivant la servlet [Spring MVC](http://docs.spring.io/spring/docs/current/spring-framework-reference/html/mvc.html), `franceconnect-servlet.xml` :

````xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:mvc="http://www.springframework.org/schema/mvc"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:tx="http://www.springframework.org/schema/tx"
	xmlns:context="http://www.springframework.org/schema/context"
	xmlns:security="http://www.springframework.org/schema/security"
	xmlns:oauth="http://www.springframework.org/schema/security/oauth2"
	xmlns:util="http://www.springframework.org/schema/util"
	xsi:schemaLocation="http://www.springframework.org/schema/security/oauth2 http://www.springframework.org/schema/security/spring-security-oauth2-2.0.xsd
		http://www.springframework.org/schema/mvc http://www.springframework.org/schema/mvc/spring-mvc-4.1.xsd
		http://www.springframework.org/schema/security http://www.springframework.org/schema/security/spring-security-4.0.xsd
		http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-4.1.xsd
		http://www.springframework.org/schema/util http://www.springframework.org/schema/util/spring-util-4.1.xsd
		http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx-4.1.xsd
		http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context-4.1.xsd">

    <!-- permettre la configuration via des annotations sous net.fenyo.franceconnect -->
    <mvc:annotation-driven />
    <context:component-scan base-package="net.fenyo.franceconnect" />

    <!-- importer les valeurs des paramètres de configuration de l'accès à France Connect -->
    <context:property-placeholder location="META-INF/config.properties" />

    <!-- mappings d'URI directs, sans nécessiter de passer par un contrôleur -->
    <mvc:resources mapping="/static/**" location="/static/" />
    <mvc:resources mapping="/js/**" location="/js/" />
    <mvc:resources mapping="/css/**" location="/css/" />
    <mvc:resources mapping="/images/**" location="/images/" />
    <mvc:resources mapping="/html-noauth/**" location="/html-noauth/" />
    <mvc:resources mapping="/html/**" location="/html-noauth/" />
    <mvc:resources mapping="/jsp-noauth/**" location="/jsp-noauth/" />

    <!-- mappings directs dont les URI sont déclarées, à la fin de ce fichier de configuration, comme nécessitant une authentification valide -->
    <mvc:resources mapping="/html-needauth/**" location="/html-needauth/" />
    <mvc:resources mapping="/jsp-needauth/**" location="/jsp-needauth/" />

    <!-- indiquer à Spring MVC comment résoudre l'emplacement des vues à partir de leur nom -->
    <bean class="org.springframework.web.servlet.view.InternalResourceViewResolver">
      <property name="prefix" value="/WEB-INF/views/" />
      <property name="suffix" value=".jsp" />
    </bean>

    <!-- injecter automatiquement les informations d'authentification dans le contexte -->
    <mvc:interceptors>
      <bean class="org.mitre.openid.connect.web.UserInfoInterceptor" />
    </mvc:interceptors>
	
    <!-- signaler à Spring Security d'utiliser un authentication manager contenant un authentication provider qui est une instance de OIDCAuthenticationProvider fourni par MitreID Connect -->
    <!-- OIDCAuthenticationProvider se charge de contacter le user info endpoint avec l'authorization bearer pour récupérer les informations détaillées concernant l'utilisateur -->
    <security:global-method-security pre-post-annotations="enabled" proxy-target-class="true" authentication-manager-ref="authenticationManager" />

    <bean id="openIdConnectAuthenticationProvider" class="org.mitre.openid.connect.client.OIDCAuthenticationProvider" />

    <security:authentication-manager alias="authenticationManager">
      <security:authentication-provider ref="openIdConnectAuthenticationProvider" />
    </security:authentication-manager>

    <!-- création du authRequestUrlBuilder, utilisé par le filtre de pré-authentification MitreID Connect fourni à Spring Security -->
    <bean class="org.mitre.openid.connect.client.service.impl.PlainAuthRequestUrlBuilder" id="plainAuthRequestUrlBuilder" />

    <!-- création d'un bean servant à stocker l'URI correspondant au fournisseur d'identité (provider représentant l'issuer) France Connect (https://fcp.integ01.dev-franceconnect.fr), ce bean étant fourni par la suite au filtre MitreID Connect -->
    <bean class="org.mitre.openid.connect.client.service.impl.StaticSingleIssuerService" id="staticIssuerService">
      <property name="issuer" value="${net.fenyo.franceconnect.config.oidc.issuer}" />
    </bean>	

    <!-- création d'un bean stockant les trois enpoints du fournisseur d'identité France Connect (https://fcp.integ01.dev-franceconnect.fr), ce bean étant fourni par la suite au filtre MitreID Connect -->
    <bean class="org.mitre.openid.connect.client.service.impl.StaticServerConfigurationService" id="staticServerConfigurationService">
      <property name="servers">
        <map>
          <entry key="${net.fenyo.franceconnect.config.oidc.issuer}">
            <bean class="org.mitre.openid.connect.config.ServerConfiguration">
              <property name="issuer" value="${net.fenyo.franceconnect.config.oidc.issuer}" />
              <property name="authorizationEndpointUri" value="${net.fenyo.franceconnect.config.oidc.authorizationendpointuri}" />
              <property name="tokenEndpointUri" value="${net.fenyo.franceconnect.config.oidc.tokenendpointuri}" />
              <property name="userInfoUri" value="${net.fenyo.franceconnect.config.oidc.userinfoendpointuri}" />
            </bean>
          </entry>
        </map>
      </property>
    </bean>

    <!-- création d'un bean stockant les paramètres et le endpoint du fournisseur de service, ce bean étant fourni par la suite au filtre MitreID Connect -->
    <bean class="org.mitre.openid.connect.client.service.impl.StaticClientConfigurationService" id="staticClientConfigurationService">
      <property name="clients">
        <map>
          <entry key="${net.fenyo.franceconnect.config.oidc.issuer}">
            <bean class="org.mitre.oauth2.model.RegisteredClient">

              <property name="scope">
                <set value-type="java.lang.String">
                  <value>openid</value>
                  <value>gender</value>
                  <value>birthdate</value>
                  <value>birthcountry</value>
                  <value>birthplace</value>
                  <value>given_name</value>
                  <value>family_name</value>
                  <value>email</value>
                  <value>address</value>
                  <value>preferred_username</value>
                  <value>phone</value>
                  <!-- <value>profile</value> -->
                </set>
            </property>

            <property name="tokenEndpointAuthMethod" value="SECRET_POST" />
            <property name="clientId" value="${net.fenyo.franceconnect.config.oidc.clientid}" />
            <property name="clientSecret" value="${net.fenyo.franceconnect.config.oidc.clientsecret}" />

            <!-- l'URI de redirection est imposée par MitreID Connect (en dur dans le code source de MitreID Connect) : /openid_connect_login -->
            <!-- cette configuration ne sert qu'aux validations de sécurité -->
            <property name="redirectUris">
              <set>
                <value>${net.fenyo.franceconnect.config.oidc.redirecturi}</value>
              </set>
            </property>

          </bean>
        </entry>
      </map>
    </property>
  </bean>

  <!-- URI vers lesquelles l'utilisateur est redirigé en cas d'erreur d'authentification -->
  <bean id="authenticationFailureHandler" class="net.fenyo.franceconnect.AuthenticationFailureHandler">
    <property name="defaultFailureUrl" value="${net.fenyo.franceconnect.config.oidc.authenticationerroruri}" />
	<property name="exceptionMappings">
	  <props>
		<prop key="org.springframework.security.authentication.AuthenticationServiceException">${net.fenyo.franceconnect.config.oidc.authenticationerroruri}</prop>
      </props>
    </property>
  </bean>

  <!-- création d'un filtre de pré-authentification Spring Security implémenté par MitreID Connect et configuré en référençant les beans MitreID Connect de configuration définis précédemment -->
  <bean id="openIdConnectAuthenticationFilter" class="org.mitre.openid.connect.client.OIDCAuthenticationFilter">
    <property name="authenticationManager" ref="authenticationManager" />
    <property name="issuerService" ref="staticIssuerService" />
    <property name="serverConfigurationService" ref="staticServerConfigurationService" />
    <property name="clientConfigurationService" ref="staticClientConfigurationService" />
    <property name="authRequestUrlBuilder" ref="plainAuthRequestUrlBuilder" />
    <!-- propriété propre à Spring Security, proposée par la classe parente de OIDCAuthenticationFilter : org.springframework.security.web.authentication.AbstractAuthenticationProcessingFilter
         le comportement en cas d'erreur est défini par le bean authenticationFailureHandler, défini précédemment -->
    <property name="authenticationFailureHandler" ref="authenticationFailureHandler" />
  </bean>

  <!-- création d'un bean servant à stocker l'URI correspondant au point d'entrée d'authentification via Spring Security
       il s'agit du callback endpoint du fournisseur de services, qui reçoit le code d'autorisation -->
  <bean id="authenticationEntryPoint" class="org.springframework.security.web.authentication.LoginUrlAuthenticationEntryPoint">
    <constructor-arg value="${net.fenyo.franceconnect.config.oidc.redirecturi}" />
  </bean>

  <!-- implémentation de la séquence de déconnexion France Connect -->
  <bean id="logoutHandler" class="net.fenyo.franceconnect.LogoutHandler">
    <property name="logoutUri" value="${net.fenyo.franceconnect.config.oidc.logouturi}" />
    <property name="afterLogoutUri" value="${net.fenyo.franceconnect.config.oidc.afterlogouturi}" />
  </bean>

  <!-- configuration de Spring Security
       note : l'attribut entry-point-ref sert à déclarer le point d'entrée d'authentification en cas d'accès à une URI nécessitant un rôle authentifié -->
  <security:http auto-config="false" use-expressions="true" disable-url-rewriting="true" entry-point-ref="authenticationEntryPoint" pattern="/**">

    <!-- déclaration du filtre MitreID Connect -->
    <security:custom-filter before="PRE_AUTH_FILTER" ref="openIdConnectAuthenticationFilter" />

    <!--
     configuration de Spring Security avec :
     - l'URI de logout utilisée par le bouton France Connect ou le fournisseur de service pour initier la séquence de logout, afin que Spring Security puisse détecter la demande de logout
     - le bean à invoquer après le logout effectif de l'application : ce bean se charge d'implémenter la cinématique de logout de France Connect :
       - redirection de l'utilisateur chez France Connect, qui lui propose aussi de se déloguer de France Connect,
       - retour vers le fournisseur de service
    -->
    <security:logout success-handler-ref="logoutHandler" logout-url="/${net.fenyo.franceconnect.config.oidc.startlogouturi}" />
    <!-- France Connect réalise le logout via GET et non POST ; pour que Spring Security le supporte, il faut désactiver le filtre anti-csrf. Il n'y a néanmoins pas de vulnérabilité csrf permettant de déloguer l'utilisateur à son insu car la norme OpenID Connect impose une validation par l'utilisateur de sa déconnexion, donc France Connect présente une mire de demande de déconnexion. -->
    <security:csrf disabled="true" />

    <!-- déclaration des URI nécessitant une authentification valide -->
    <security:intercept-url pattern="/html-needauth/*" access="isFullyAuthenticated()" />
    <security:intercept-url pattern="/jsp-needauth/*" access="isFullyAuthenticated()" />

  </security:http>
</beans>
````

## Création de nouvelles ressources

### Répertoires

Consultez les mappings au début du fichier [`franceconnect-servlet.xml`](#intégration-de-mitreid-connect-dans-spring) afin de connaître les sous-répertoires de `FournisseurDeServices/src/main/webapp/` où rajouter :

- des fichiers statiques, des pages html, du code JavaScript, des pages de styles CSS et des images accessible sans nécessiter une authentification au préalable

- des fichiers statiques, des pages html, du code JavaScript, des pages de styles CSS et des images accessible nécessitant une authentification au préalable

En cas d'accès à une ressource protégée mais sans authentification préalable de l'utilisateur, la cinématique d'authentification est automatiquement lancée puis le navigateur est redigiré à nouveau vers la ressource à laquelle il peut enfin accéder.

### Ressources statiques

Les accès aux ressources statiques (pages html, code JavaScript, pages de styles CSS et images) nécessitant une authentification ne sont **pas** tracés. Ces ressources n'ont pas accès à l'identité de l'utilisateur.

### Pages jsp

Pour tracer l'accès direct à une page jsp, c'est-à-dire sans passer par le contrôleur Spring MVC, celle-ci doit inclure `<% net.fenyo.franceconnect.Tools.log(request.getRequestURI()); %>`.

Les pages jsp à accès direct sans passer par un contrôleur n'ont pas accès à l'identité de l'utilisateur (néanmoins, cet accès est possible en écrivant du code Java spécifique dans ces pages).

### Contrôleur et vues

Le contrôleur a accès à l'identité de l'utilisateur. Les vues, c'est-à-dire les pages jsp accessible après passage par le contrôleur, ont aussi accès au données d'identité de l'utilisateur. 

Pour créer un mapping de requête au sein du contrôleur, il faut modifier la classe net.fenyo.franceconnect.WebController en y ajoutant une méthode spécifique. Le mapping est configuré par une annotation `@RequestMapping`, par exemple : `@RequestMapping(value = "/user", method = RequestMethod.GET)`. Si la requête nécessite une authentification, il faut le signaler par l'annotation suivante : `@PreAuthorize("isFullyAuthenticated()")`. Pour tracer cette requête, la méthode spécifique doit débuter par une invocation de la méthode statique `log` de la classe `Tools`, par exemple : `Tools.log("accès à /user", logger);`. La variable ` logger` est une variable d'instance du contrôleur.

Voici un exemple de méthode spécifique qui mappe l'accès à /user et invoque la vue user :
````java
	@RequestMapping(value = "/user", method = RequestMethod.GET)
	@PreAuthorize("isFullyAuthenticated()")
	public ModelAndView user(final Principal p) {
		Tools.log("accès à /user", logger);
		final ModelAndView mav = new ModelAndView("user");
		return mav;
	}
````

La vue a accès à l'identité de l'utilisateur via la variable `userInfo` automatiquement injectée dans le modèle. Elle doit inclure le bouton FranceConnect, notamment pour permettre la déconnexion de l'utilisateur.

Voici un exemple de vue affichant les informations d'identité de l'utilisateur :
````html
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>Fournisseur de services France Connect</title>
  </head>

  <body>
    <!-- inclusion du code JavaScript de FranceConnect.
         Ce code force le navigateur à récupérer la CSS suivante : https://fcp.integ01.dev-franceconnect.fr/stylesheets/franceconnect.css
         Cette CSS définit le attributs de style pour l'élément d'id fconnect-profile -->
    <script src="${ oidcAttributes.fcbuttonuri }"></script>
    <!-- inclusion du bouton France Connect -->
    <div style="color: #000000; background-color: #000ccc" id="fconnect-profile" data-fc-logout-url="${ oidcAttributes.startlogouturi }"><br/>
    <a href="#">${ userInfo.givenName } ${ userInfo.familyName }&nbsp;<i class="material-icons tiny">keyboard_arrow_down</i></a><br/>&nbsp;</div>

    Cette page de fourniture du service n'est accessible qu'aux utilisateurs authentifiés.
    Vous êtes <b>correctement authentifié</b> via France Connect.<br/>
<pre>
Utilisateur (user info) :
  - sujet (utilisateur)  : ${ userInfo.sub } 
  - genre                : ${ userInfo.gender } 
  - date de naissance    : ${ userInfo.birthdate }
  - prénom               : ${ userInfo.givenName } 
  - nom                  : ${ userInfo.familyName } 
  - courriel             : ${ userInfo.email }
  - addresse postale :
    - rue               : ${ userInfo.address.streetAddress } 
    - commune           : ${ userInfo.address.locality }
    - région            : ${ userInfo.address.region }
    - code postal       : ${ userInfo.address.postalCode }
    - pays              : ${ userInfo.address.country }
    - lieu de naissance : ${ oidcBirthplace }
    - pays de naissance : ${ oidcBirthcountry }
valeur JSON complète : ${ userInfo.source }
    </pre>
  </body>
</html>
````

Une méthode spécifique peut ne pas imposer une authentification préalable. Dans ce cas, la vue peut être construite de manière à activer ou désactiver des blocs selon que l'authentification a été réalisée. Pour cela, il faut utiliser la bibliothèse que tags de Spring Security et encadrer les blocs nécessitant une authentification dans un élément `<authorize access="isFullyAuthenticated()">` et ceux à afficher uniquement en l'absence d'authentification dans un élément `<authorize access="!isFullyAuthenticated()">`. Le bouton FranceConnect doit être inclus uniquement lors d'un accès authentifié.

Voici un exemple de méthode spécifique correspondant à ce scénario :
````java
	@RequestMapping(value = "/user", method = RequestMethod.GET)
	public ModelAndView user(final Principal p) {
		Tools.log("accès à /user", logger);
		final ModelAndView mav = new ModelAndView("user");
		return mav;
	}
````

Voici la vue associée :
````html
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>
<%@ page session="false" %>

<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>Fournisseur de services France Connect</title>
  </head>

  <body>
    <security:authorize access="isFullyAuthenticated()">

      <!-- inclusion du code JavaScript de France Connect.
           Ce code force le navigateur à récupérer la CSS suivante : https://fcp.integ01.dev-franceconnect.fr/stylesheets/franceconnect.css
           Cette CSS définit le attributs de style pour l'élément d'id fconnect-profile -->
      <script src="${ oidcAttributes.fcbuttonuri }"></script>
      <!-- inclusion du bouton France Connect -->
      <div style="color: #000000; background-color: #000ccc" id="fconnect-profile" data-fc-logout-url="${ oidcAttributes.startlogouturi }"><br/>
      <a href="#">${ userInfo.givenName } ${ userInfo.familyName }&nbsp;<i class="material-icons tiny">keyboard_arrow_down</i></a><br/>&nbsp;</div>

    </security:authorize>

    <H1>Page d'accueil du service</H1>
    Cette page d'accueil du service est accessible à tous les internautes, authentifiés ou non.
    <HR/>

    <security:authorize access="isFullyAuthenticated()">
      Vous vous êtes précédemment <b>correctement authentifié</b> auprès du fournisseur de services via France Connect.<br/>

    </security:authorize>

    <security:authorize access="!isFullyAuthenticated()">
      Vous n'êtes <b>pas</b> authentifié à ce fournisseur de services.<br/>
    </security:authorize>
  </body>
</html>
````

## Déploiement

### Prérequis

Voici la liste des prérequis nécessaires à l'utilisation opérationnelle de ce produit :
- disposer d'un environnement Unix, Linux ou Windows
- installer un environnement JDK 7 ou version supérieure
- installer Maven 3.0.4 ou version supérieure
- disposer d'une connexion Internet (accès direct ou proxy)
- disposer d'un navigateur Internet

### Démarrage dans un serveur Tomcat embarqué

- Démarrage avec Tomcat sur un serveur avec accès direct à Internet :
  `mvn clean tomcat7:run`
  
- Démarrage avec Tomcat sur un serveur nécessitant le passage par un proxy web pour accéder à Internet (remplacer PROXYHOST et PROXYPORT par les valeurs correspondant au proxy web) :
  - `mvn -Dhttps.proxyHost=PROXYHOST -Dhttps.proxyPort=PROXYPORT clean tomcat7:run`
  - Attendre le message `INFOS: Starting ProtocolHandler ["http-bio-80"]`, signifiant le lancement complet de Tomcat, avant de passer à l'étape suivante
  - Lancer alors un navigateur sur http://127.0.0.1/

- Pour modifier le port local par défaut (80), au cas où il y aurait par exemple déjà un serveur sur ce port, ou au cas où l'utilisateur courant n'aurait pas les droits pour écouter sur un port privilégié (inférieur strict à 1024), rajoutez l'option `-Dnet.fenyo.franceconnect.config.listen.port=PORT` sur la ligne de commande mvn (remplacer PORT par la valeur du port TCP local d'écoute souhaité).

### Démarrage dans un serveur Jetty embarqué

- Démarrage avec Jetty sur un serveur avec accès direct à Internet : `mvn clean jetty:run`

- Démarrage avec Jetty sur un serveur nécessitant le passage par un proxy web pour accéder à Internet (remplacer PROXYHOST et PROXYPORT par les valeurs correspondant au proxy web) :
  - `mvn -Dhttps.proxyHost=PROXYHOST -Dhttps.proxyPort=PROXYPORT clean jetty:run`
  - Attendre le message `[INFO] Started Jetty Server`, signifiant le lancement complet de Jetty, avant de passer à l'étape suivante.
- Lancer alors un navigateur sur http://127.0.0.1/

- Pour modifier le port local par défaut (80), au cas où il y aurait par exemple déjà un serveur sur ce port, ou au cas où l'utilisateur courant n'aurait pas les droits pour écouter sur un port privilégié (inférieur strict à 1024), rajoutez l'option `-Dnet.fenyo.franceconnect.config.listen.port=PORT` sur la ligne de commande mvn (remplacer PORT par la valeur du port TCP local d'écoute souhaité).

### Démarrage dans Eclipse

- installer [Eclipse](https://www.eclipse.org/downloads/) Neon ou version supérieure (afin d'éviter de devoir installer certaines extensions spécifiques pour le support de composants comme Maven par exemple)
- importer le projet dans [Eclipse](https://www.eclipse.org/downloads/)
- &Agrave; chaque modification du fichier `pom`, sélectionner l'élément racine du projet dans l'explorateur de projet, faire "bouton droite" sur cet élément, choisir *Maven* dans le menu déroulant puis *Update Project...*.
- Pour (re-)compiler le projet, sélectionner dans le menu Projet l'entrée *Clean...* puis *Build Project*.
- Pour démarrer l'application, utiliser le menu Run pour accéder à *Run configurations...* ou *Debug configurations...*, créer une configuration Apache Tomcat (vous devrez disposer d'une distribution Tomcat 7 ou version supérieure), publier l'application dans le serveur et démarrer le serveur.

> :warning:  
> KIF est configuré par défaut pour se déployer dans le contexte racine (`"/"`) du serveur d'application et non pas dans un contexte correspondant à un chemin intermédiaire comme `"/poc-franceconnect"`.  [Eclipse](https://www.eclipse.org/downloads/) peut être amené à modifier le chemin de déploiement de l'application, ce qui empêche son bon fonctionnement car certaines des URL déclarées dans le fichier de configuration ne sont plus valables. Dans ce cas, il faut soit réécrire ces URL, soit repositionner correctement le chemin dans '[Eclipse](https://www.eclipse.org/downloads/), comme ceci :
> - soit interrompre Eclipse et modifier le fichier `FournisseurDeServices/.settings/org.eclipse.wst.common.component`pour que la ligne `<property name="context-root" value=""/>` contienne bien un attribut `value` vide (c'est cet attribut qui est parfois modifié par Eclipse). Puis redémarrer Eclipse.
> 
> - soit sélectionner *Show View* dans le menu déroulant Window puis *Servers*. Dans la vue Servers" qui s'affiche, double-cliquer sur le serveur (ex.: `Tomcat v8.0 Server at localhost [Stopped, Synchronized]`), la configuration du serveur s'affiche alors et l'onglet sélectionné par défaut est nommé Overview, changer pour l'onglet Modules et vérifier que la colonne Path du tableau des Web Modules chargés est vide. Si ce n'est pas le cas, cliquer sur la ligne correspondante et sur le bouton `Edit...` pour effacer le contenu du champ Path. Sauver la nouvelle configuration (entrée *Save* du menu Fichier, ou raccourci clavier `Ctrl-S`) et redémarrer le serveur.

&nbsp;

> :warning:  
> Le fichier de configuration config.properties contient deux URLs déclarées chez FranceConnect :
> - l'URL de callback (paramètres net.fenyo.franceconnect.config.oidc.redirecturi de config.properties)
> - l'URL de redirection de déconnexion (paramètre net.fenyo.franceconnect.config.oidc.afterlogouturi de config.properties)
> Si ces URL utilisent l'adresse IP 127.0.0.1, le navigateur doit être lancé sur http://127.0.0.1/
> Si ces URL utilisent le nom localhost, le navigateur doit être lancé sur http://localhost/
> En effet, les cookies de session positionnés par un serveur désigné localhost ne sont pas renvoyés à un serveur désigné 127.0.0.1 et réciproquement.
> Utiliser dans une même configuration un mélange de localhost et de 127.0.0.1 conduit à des erreurs de connexion.



----------

written with StackEdit - Support StackEdit

[![](https://cdn.monetizejs.com/resources/button-32.png)](https://monetizejs.com/authorize?client_id=ESTHdCYOi18iLhhO&summary=true)

[StackEdit](https://stackedit.io/) is a full-featured, open-source Markdown editor based on PageDown, the Markdown library used by Stack Overflow and the other Stack Exchange sites.

