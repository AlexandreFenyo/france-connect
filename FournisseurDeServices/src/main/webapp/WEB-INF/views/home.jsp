<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>
<%@ page session="false" %>

<html lang="fr">
  <head>
    <meta charset="utf-8">
    <title>Fournisseur de services France Connect</title>
    <!-- fonts -->
    <link type="text/css" rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/materialize/0.97.5/css/materialize.min.css" media="screen,projection"/>
    <!-- icône keyboard_arrow_down -->
    <link href="http://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
  </head>

  <body>

    <security:authorize access="isFullyAuthenticated()">
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
    </security:authorize>

    <H1>Page d'accueil du service</H1>
    Cette page d'accueil du service est accessible à tous les internautes, authentifiés ou non,
    contrairement à la page de fourniture du service, qui est uniquement accessible aux utilisateurs authentifiés.
    
    <HR/>

    <security:authorize access="isFullyAuthenticated()">
      Vous vous êtes précédemment <b>correctement authentifié</b> auprès du fournisseur de services via France Connect.<br/>
      <p/>
      Pour accéder à la page de fourniture du service, cliquez sur le lien suivant : <a href="<c:url value="/user" />">service</a>.<br/>
      <p/>
      Pour vous déconnecter de ce service (vous pourrez aussi choisir de vous déconnecter de France Connect) et retourner à la page publique d'accueil du service, utilisez le menu en haut de la page ou cliquez sur le lien suivant : <a href="<c:url value="/${ oidcAttributes.startlogouturi }" />">déconnexion</a>.
    </security:authorize>

    <security:authorize access="!isFullyAuthenticated()">
      Vous n'êtes <b>pas</b> authentifié à ce fournisseur de services.<br/>
      <p/>
      Pour vous authentifier sur ce service via France Connect et accéder à la page de fourniture du service, veuillez cliquer sur le lien suivant :<br/> 
      <a href="user"><img alt="France Connect" src="static/FCboutons-10.png" /></a>
    </security:authorize>

  </body>
</html>
