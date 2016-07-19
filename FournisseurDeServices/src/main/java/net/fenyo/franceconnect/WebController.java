package net.fenyo.franceconnect;

import java.security.Principal;
import org.mitre.openid.connect.model.OIDCAuthenticationToken;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.security.core.*;
import org.springframework.security.core.context.*;

@Controller
public class WebController {
	private static final Logger logger = LoggerFactory.getLogger(WebController.class);

	@Autowired
    private OidcAttributes oidcAttributes;
	
	@RequestMapping(value = "/", method = RequestMethod.GET)
	public ModelAndView home() {
		final ModelAndView mav = new ModelAndView("home");
		mav.addObject("oidcAttributes", oidcAttributes);
		return mav;
	}

	@RequestMapping(value = "/user", method = RequestMethod.GET)
	@PreAuthorize("isFullyAuthenticated()")
	public ModelAndView user(final Principal p) {
    	final Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		OIDCAuthenticationToken oidcauth = (OIDCAuthenticationToken) auth;

		// exemples d'accès en Java aux informations d'authentification :
		//   oidcauth.getIdToken().getJWTClaimsSet().getIssuer()
		//   oidcauth.getUserInfo().getAddress().getPostalCode()
		
		final ModelAndView mav = new ModelAndView("user");
		mav.addObject("oidcBirthplace", oidcauth.getUserInfo().getSource().get("birthplace"));
		mav.addObject("oidcBirthcountry", oidcauth.getUserInfo().getSource().get("birthcountry"));
		mav.addObject("oidcAttributes", oidcAttributes);
		return mav;
	}
}
