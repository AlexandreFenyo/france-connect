<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>

<html lang="en">
<head>

    <base href="${config.issuer}">

    <meta charset="utf-8">
    <title>Simple Web App - ${title}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="">
    <meta name="author" content="">

    <!-- stylesheets -->
    <link href="static/bootstrap2/css/bootstrap.css" rel="stylesheet">
    <link href="static/bootstrap2/css/bootstrap-responsive.css" rel="stylesheet">

    <!-- HTML5 shim, for IE6-8 support of HTML5 elements -->
    <!--[if lt IE 9]>
    <script src="http://html5shim.googlecode.com/svn/trunk/html5.js"></script>
    <![endif]-->

    <!-- Load jQuery up here so that we can use in-page functions -->
    <script type="text/javascript" src="static/js/lib/jquery.js"></script>
    <script type="text/javascript">
    	// safely set the title of the application
    	function setPageTitle(title) {
    		document.title = "${config.topbarTitle} - " + title;
    	}
    	
		// get the info of the current user, if available (null otherwise)
    	function getUserInfo() {
    		return ${userInfoJson};
    	}
		
		// get the authorities of the current user, if available (null otherwise)
		function getUserAuthorities() {
			return ${userAuthorities};
		}
		
		// is the current user an admin?
		// NOTE: this is just for  
		function isAdmin() {
			var auth = getUserAuthorities();
			if (auth && _.contains(auth, "ROLE_ADMIN")) {
				return true;
			} else {
				return false;
			}
		}
    </script>    
</head>

<body>

<div class="container-fluid main">
	<div class="row-fluid">
		<div class="span10 offset1">

			<h1>Hello ${ userInfo.name }</h1>

<!-- important http://stackoverflow.com/questions/11050840/call-to-j-spring-security-logout-not-working
 With spring security 4 Logout has to be done through form button. CSRF token has to be submitted along. j_spring_security_logout does not work any longer. After spending one day i got following to be working.
 http://websystique.com/spring-security/spring-security-4-logout-example/ -->

<div id="fconnect-profile" data-fc-logout-url="j_spring_security_logout"><a href="#"> le nom de l'utilisateur connecté* </a></div>
<script src="https://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js"></script>

			<div>
				<p>This page requires that the user be logged in with a valid account and the <code>ROLE_USER</code> Spring Security authority.
				If you are reading this page, <span class="text-success">you are currently logged in</span>.</p>

<pre>ALEX
<a href="<c:url value="/logout" />">Logout</a>
</pre>


				<security:authentication var="user" property="principal" />

				<p>The authorization provider will create a Principal object based on the <code>iss</code> and <code>sub</code>
				claims associated with your ID token. This value can be used as a globally unique username within the application
				(though it's not meant to be human-readable).
				Your Principal is: <code>${ user }</code></p>

				<p>The authorization provider will assign your account a set of authorities depending on how it's configured.
				Your current login has the following Spring Security authorities:</p>
				
				<ul>
					<security:authentication property="authorities" var="authorities" />
					<c:forEach items="${authorities}" var="auth">
						<li><code>${ auth }</code></li>
					</c:forEach>
				</ul>
				
				<h3>ID Token</h3>

				<p>Your ID Token has the following set of claims:</p>
				
				<security:authentication property="idToken" var="idToken" />
				<table class="table table-striped table-hover" id="idTokenTable">
					<thead>
						<tr>
							<th class="span1">Name</th>
							<th class="span11">Value</th>
						</tr>
					</thead>
					<tbody>
					</tbody>				
				</table>
				
				<p>The ID Token header contains the following claims:</p>
				
				<table class="table table-striped table-hover" id="idTokenHeader">
					<thead>
						<tr>
							<th class="span1">Name</th>
							<th class="span11">Value</th>
						</tr>
					</thead>
					<tbody>
					</tbody>				
				</table>

				<h3>User Info</h3>
				
				<p>The call to the User Info Endpoint returned the following set of claims:</p>

				<table class="table table-striped table-hover" id="userInfoTable">
					<thead>
						<tr>
							<th class="span1">Name</th>
							<th class="span11">Value</th>
						</tr>
					</thead>
					<tbody>
					</tbody>				
				</table>

			</div>

		</div>
	</div>
</div>

<script type="text/javascript">
	$(document).ready(function () {

		var idTokenString = "${ idToken.serialize() }";
		var idToken = jwt.WebTokenParser.parse(idTokenString);
		var idHeader = JSON.parse(jwt.base64urldecode(idToken.headerSegment));
		var idClaims = JSON.parse(jwt.base64urldecode(idToken.payloadSegment));
	
		_.each(idClaims, function(val, key, list) {
			if (_.contains(["iat", "exp", "auth_time", "nbf"], key)) {
				// it's a date field, parse and print it
				var date = new Date(val * 1000);
				$('#idTokenTable tbody').append('<tr><td>' + _.escape(key) + '</td><td><span title="' + _.escape(val) + '">' + date + '</span></td></tr>');
			} else {
				$('#idTokenTable tbody').append('<tr><td>' + _.escape(key) + '</td><td>' + _.escape(val) + '</td></tr>');
			}
		});
		
		_.each(idHeader, function(val, key, list) {
			if (_.contains(["iat", "exp", "auth_time", "nbf"], key)) {
				// it's a date field, parse and print it
				var date = new Date(val * 1000);
				$('#idTokenHeader tbody').append('<tr><td>' + _.escape(key) + '</td><td><span title="' + _.escape(val) + '">' + date + '</span></td></tr>');
			} else {
				$('#idTokenHeader tbody').append('<tr><td>' + _.escape(key) + '</td><td>' + _.escape(val) + '</td></tr>');
			}
		});
		
		var userInfo = ${ userInfoJson };
		_.each(userInfo, function(val, key, list) {
			$('#userInfoTable tbody').append('<tr><td>' + _.escape(key) + '</td><td>' + _.escape(val) + '</td></tr>');
		});
	});

</script>

<script type="text/javascript" src="static/bootstrap2/js/bootstrap.js"></script>
<script type="text/javascript" src="static/js/lib/underscore.js"></script>
<script type="text/javascript" src="static/js/lib/jwt.js"></script>
</body>
</html>
