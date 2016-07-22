<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>

<html lang="fr">
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>Fournisseur de services France Connect</title>
    <!-- fonts -->
    <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.5/css/materialize.min.css" media="screen,projection"/>
    <!-- icône keyboard_arrow_down -->
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
  </head>

  <body>

    <!-- chargement de l'id token -->
    <security:authentication property="idToken" var="idToken" />
    <!--
      La configuration de l'intercepteur Spring MVC UserInfoInterceptor permet de s'affranchir de la déclaration suivante :
      <security:authentication property="userInfo" var="userInfo" />
    -->
    
    <!-- inclusion du code JavaScript de France Connect.
         Ce code force le navigateur à récupérer la CSS suivante : https://fcp.integ01.dev-franceconnect.fr/stylesheets/franceconnect.css
         Cette CSS définit le attributs de style pour l'élément d'id fconnect-profile -->
    <script src="${ oidcAttributes.fcbuttonuri }"></script>
    <!-- inclusion du bouton France Connect -->
    <div style="color: #000000; background-color: #000ccc" id="fconnect-profile" data-fc-logout-url="${ oidcAttributes.startlogouturi }"><br/>
    <a href="#">${ userInfo.givenName } ${ userInfo.familyName }&nbsp;<i class="material-icons tiny">keyboard_arrow_down</i></a><br/>&nbsp;</div>

    <H1>Page de fourniture du service</H1>
    Cette page de fourniture du service n'est accessible qu'aux utilisateurs authentifiés.

    <HR/>

    Vous êtes <b>correctement authentifié</b> via France Connect.<br/>
    <P/>
    Pour accéder à la page publique d'accueil du service sans vous déconnecter, cliquez sur le lien suivant : <a href="<c:url value="/" />">accueil</a>.<br/>
    <P/>
    Pour vous déconnecter de ce service (vous pourrez aussi choisir de vous déconnecter de France Connect) et retourner à la page publique d'accueil du service, utilisez le menu en haut de la page ou cliquez sur le lien suivant : <a href="<c:url value="/${ oidcAttributes.startlogouturi }" />">déconnexion</a>.

    <HR/>

    <pre>
Jeton (id token) :
  Entête :
  - Type de jeton : ${ idToken.header.type }
  - Algorithme    : ${ idToken.header.algorithm }
  Corps :
  - émetteur               : ${ idToken.JWTClaimsSet.issuer }
  - sujet (utilisateur)    : ${ idToken.JWTClaimsSet.subject }
  - audience (client id)   : ${ idToken.JWTClaimsSet.audience }
  - date d'expiration      : ${ idToken.JWTClaimsSet.expirationTime }
  - date de génération     : ${ idToken.JWTClaimsSet.issueTime }
  - nonce                  : ${ idToken.JWTClaimsSet.claims["nonce"] }
  - fournisseur d'identité : ${ idToken.JWTClaimsSet.claims["idp"] }
  - niveau eIDAS           : ${ idToken.JWTClaimsSet.claims["acr"] }

valeur complète du token : ${ idToken.parsedString }
    </pre>

    <hr/>

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
