package net.fenyo.franceconnect;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.mitre.openid.connect.model.OIDCAuthenticationToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

public class Tools {
	private static final Logger logger = LoggerFactory.getLogger(LogoutHandler.class);

	private static String buildMessage(final String msg, final HttpServletRequest _request, final Authentication _auth) {
		String output = "log fc: msg [" + msg + "]";

		// logger les paramètres d'authentification
		if (_auth == null && SecurityContextHolder.getContext() == null) output += "; auth: security context is null";
		else {
			final Authentication auth = _auth != null ? _auth : SecurityContextHolder.getContext().getAuthentication();
			if (AnonymousAuthenticationToken.class.isInstance(auth)) output += "; auth: anonymous";
			else {
				final OIDCAuthenticationToken oidcauth = (OIDCAuthenticationToken) auth;

				if (oidcauth == null) output += "; auth: oidc authentication token is null";
				else {
					if (oidcauth.getIdToken() == null) output += "; auth: id token is null";
					else output += "; auth: id token [" + oidcauth.getIdToken().getParsedString() + "]";

					if (oidcauth.getUserInfo() == null) output += "; auth: user info is null";
					else output += "; auth: user info [" + oidcauth.getUserInfo().getSource() + "]";
				}
			}
		}

		// logger les paramètres de session et de requête
		if (_request == null && RequestContextHolder.getRequestAttributes() == null) output += "; req: request attributes are null";
		else {
			final HttpServletRequest request = _request != null ? _request : ((ServletRequestAttributes) RequestContextHolder.getRequestAttributes()).getRequest();
			if (request == null) output += "; req: request is null";
			else {
				output += "; req: session id [" + request.getRequestedSessionId() + "]";
				output += "; req: remote addr [" + request.getRemoteAddr() + "]";
				output += "; req: remote port [" + request.getRemotePort() + "]";
				output += "; req: request [" + request.toString() + "]";
			}
		}
		return output;
	}

	public static void log(final String msg, final HttpServletRequest request, final Authentication auth, final Logger logger) {
		logger.info(buildMessage(msg, request, auth));
	}

	public static void log(final String msg, Logger logger) {
		logger.info(buildMessage(msg, null, null));
	}

	public static void log(final String msg) {
		logger.info(buildMessage(msg, null, null));
	}
}
