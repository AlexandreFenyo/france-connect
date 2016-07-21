package net.fenyo.franceconnect;

import javax.servlet.http.HttpSessionEvent;
import javax.servlet.http.HttpSessionListener;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.context.support.WebApplicationContextUtils;

public class SessionListener implements HttpSessionListener {
	private static final Logger logger = LoggerFactory.getLogger(SessionListener.class);

	@Override
	public void sessionCreated(HttpSessionEvent se) {
		// positionner le timeout de session
		se.getSession().setMaxInactiveInterval(
				((OidcAttributes) WebApplicationContextUtils.getWebApplicationContext(se.getSession().getServletContext()).getBean("oidcAttributes")).getSessionTimeout() * 60
		);	
	}

	@Override
	public void sessionDestroyed(HttpSessionEvent se) {}
}
