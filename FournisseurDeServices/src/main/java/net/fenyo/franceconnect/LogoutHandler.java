package net.fenyo.franceconnect;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.mitre.openid.connect.model.OIDCAuthenticationToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.*;
import org.springframework.web.util.UriComponents;
import org.springframework.web.util.UriComponentsBuilder;

public class LogoutHandler implements LogoutSuccessHandler {
	private static final Logger logger = LoggerFactory.getLogger(LogoutHandler.class);

	String logout_uri = null;
	String after_logout_uri = null;
	
	public LogoutHandler() {}

	public void setLogoutUri(final String logout_uri) {
		this.logout_uri = logout_uri;
	}

	public String getLogoutUri() {
		return logout_uri;
	}

	public void setAfterLogoutUri(final String after_logout_uri) {
		this.after_logout_uri = after_logout_uri;
	}

	public String getAfterLogoutUri() {
		return after_logout_uri;
	}

	public void onLogoutSuccess(final HttpServletRequest request, final HttpServletResponse response, final Authentication auth)
			throws IOException, ServletException {
		final OIDCAuthenticationToken oidcauth = (OIDCAuthenticationToken) auth;

		final UriComponents uriComponents =
	            UriComponentsBuilder.fromHttpUrl(getLogoutUri())
	            	.queryParam("id_token_hint", oidcauth.getIdToken().serialize())
	            	.queryParam("post_logout_redirect_uri", getAfterLogoutUri())
	                .build()
	                .encode();

		request.getSession().invalidate();
		response.sendRedirect(uriComponents.toUriString());
	}
}
