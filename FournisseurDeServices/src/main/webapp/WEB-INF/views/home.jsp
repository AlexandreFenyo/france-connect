<%@ taglib prefix="security" uri="http://www.springframework.org/security/tags" %>
<%@ page session="false" %>
<div class="container-fluid main">
	<div class="row-fluid">
		<div class="span10 offset1">
			<div>
				<p class="well">
					<security:authorize access="isFullyAuthenticated()">
						<b><span class="text-success">You are currently logged in.</span></b>
<div id="fconnect-profile" data-fc-logout-url="/logout"><a href="#"> le nom de l'utilisateur connecté* </a></div>
<script src="http://fcp.integ01.dev-franceconnect.fr/js/franceconnect.js"></script>

					</security:authorize>
					<security:authorize access="!isFullyAuthenticated()">
						<b><span class="text-error">You are <em>NOT</em> currently logged in.</span></b>			
<a href="user"><img src="static/FCboutons-10.png"/></a>
					</security:authorize>
				</p>
			
				<ul>
					<li><a href="user">User</a>, requires the user to be logged in with the <code>ROLE_USER</code> Spring Security authority.</li>
					<security:authorize access="isFullyAuthenticated()">
						<li><a href="logout">Logout</a>, log out directly and return to this page.</li>
					</security:authorize>

<a href="/invalidate-spring-session?target=redirect:/html-noauth/infos.html">/invalidate-spring-session => /html-noauth/infos.html</a><br/>
<a href="/invalidate-spring-session?target=redirect:/jsp-noauth/infos.jsp">/invalidate-spring-session => /jsp-noauth/infos.jsp</a><br/>

<a href="/set-attribute-in-session?target=redirect:/html-noauth/infos.html">/set-attribute-in-session => /html-noauth/infos.html</a><br/>
<a href="/set-attribute-in-session?target=redirect:/jsp-noauth/infos.jsp">/set-attribute-in-session => /jsp-noauth/infos.jsp</a><br/>

<a href="/remove-attribute-from-session?target=redirect:/html-noauth/infos.html">/remove-attribute-from-session => /html-noauth/infos.html</a><br/>
<a href="/remove-attribute-from-session?target=redirect:/jsp-noauth/infos.jsp">/remove-attribute-from-session => /jsp-noauth/infos.jsp</a><br/>

				</ul>
			</div>
		</div>
	</div>
</div>

