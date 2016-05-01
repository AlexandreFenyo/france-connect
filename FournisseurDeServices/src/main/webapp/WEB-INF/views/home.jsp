<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>
<%@ page session="false" %>
<div class="container-fluid main">
	<div class="row-fluid">
		<div class="span10 offset1">
			<div>
				<p class="well">
					<security:authorize access="hasRole('ROLE_USER')">
						<b><span class="text-success">You are currently logged in.</span></b>
<div id="fconnect-profile" data-fc-logout-url="/logout"><a href="#"> le nom de l'utilisateur connecté* </a></div>
<script src="http://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js"></script>

					</security:authorize>
					<security:authorize access="!hasRole('ROLE_USER')">
						<b><span class="text-error">You are <em>NOT</em> currently logged in.</span></b>			
<a href="user"><img src="static/FCboutons-10.png"/></a>
					</security:authorize>
				</p>
			
				<ul>
					<li><a href="user">User</a>, requires the user to be logged in with the <code>ROLE_USER</code> Spring Security authority.</li>
					<security:authorize access="hasRole('ROLE_USER')">
						<li><a href="j_spring_security_logout">Logout</a>, log out directly and return to this page.</li>
					</security:authorize>
				</ul>
			</div>
		</div>
	</div>
</div>

