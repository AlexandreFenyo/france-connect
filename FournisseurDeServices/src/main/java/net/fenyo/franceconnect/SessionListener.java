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

import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.web.context.support.WebApplicationContextUtils;

public class SessionListener implements HttpSessionListener {
	private static final Logger logger = LoggerFactory.getLogger(SessionListener.class);
	private int count = 0;

	@Override
	public void sessionCreated(HttpSessionEvent se) {
		// positionner le timeout de session
		se.getSession().setMaxInactiveInterval(
				((OidcAttributes) WebApplicationContextUtils.getWebApplicationContext(se.getSession().getServletContext()).getBean("oidcAttributes")).getSessionTimeout() * 60
		);
		count++;
		Tools.log("création de session " + se.getSession().getId() + " (" + count + " session" + (count > 1 ? "s" : "" + ")"), logger);
	}

	// Si le contexte est rechargé sans que le conteneur de servlet soit redémarré, le nombre de sessions peut devenir négatif
	// car le compteur est remis à 0 au rechargement du contexte puis la fermeture (ou garbage collection suite à expiration) d'une session crée avant le rechargement du contexte décrémente le compteur.
	// De même, les sessions qui seraient créées avant le chargement du contexte auraient le même effet au moment de leur fermeture (ou garbage collection suite à expiration).
	@Override
	public void sessionDestroyed(HttpSessionEvent se) {
		count--;
		Tools.log("destruction de session " + se.getSession().getId() + " (" + count + " session" + (count > 1 ? "s" : "") + ")", logger); 
	}
}
