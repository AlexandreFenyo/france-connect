package net.fenyo.franceconnect;

/*
 * Copyright 2016 Alexandre Fenyo - alex@fenyo.net - http://fenyo.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.mitre.openid.connect.model.OIDCAuthenticationToken;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.*;
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

		Tools.log("logout", request, auth, logger);

		// Traitement du cas où on se déconnecte via le bouton France Connect alors qu'on n'est pas ou plus authentifié.
		// Ce cas se produit par exemple si deux onglets sont ouverts sur l'application et sont connectés via la même session,
		// et que l'un des onglets a réalisé une déconnexion via le bouton France Connect.
		// Si une déconnexion est alors initiée par le bouton France Connect du second onglet, il n'y a pas de contexte d'authentification,
		// donc on ne peut ni ne doit renvoyer vers France Connect pour une déconnexion.
		if (oidcauth == null || oidcauth.getIdToken() == null) response.sendRedirect(getAfterLogoutUri());
		else response.sendRedirect(UriComponentsBuilder.fromHttpUrl(getLogoutUri())
			 .queryParam("id_token_hint", oidcauth.getIdToken().serialize())
	         .queryParam("post_logout_redirect_uri", getAfterLogoutUri())
	         .build()
	         .encode().toUriString());
	}
}
