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

import java.net.URL;
import java.nio.charset.Charset;
import java.security.Principal;
import java.util.List;
import javax.servlet.http.HttpServletRequest;

import org.mitre.openid.connect.model.OIDCAuthenticationToken;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.servlet.view.RedirectView;
import org.springframework.security.core.*;
import org.springframework.security.core.context.*;

import com.google.gson.JsonObject;

import org.apache.commons.codec.binary.Hex;
import org.apache.commons.lang3.ArrayUtils;

import org.apache.http.NameValuePair;
import org.apache.http.client.utils.URLEncodedUtils;

import org.bouncycastle.crypto.CipherParameters;
import org.bouncycastle.crypto.engines.AESEngine;
import org.bouncycastle.crypto.modes.CBCBlockCipher;
import org.bouncycastle.crypto.paddings.PKCS7Padding;
import org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher;
import org.bouncycastle.crypto.params.KeyParameter;
import org.bouncycastle.crypto.params.ParametersWithIV;

@Controller
public class WebController {
	private static final Logger logger = LoggerFactory.getLogger(WebController.class);

	@Autowired
    private OidcAttributes oidcAttributes;
	
	// accès à la page d'accueil du service : pas d'authentification requise
	@RequestMapping(value = "/", method = RequestMethod.GET)
	public ModelAndView home() {
		Tools.log("accès à /", logger);

		// si le mode debug n'est pas positionné, seul l'IdP est activé
		if (oidcAttributes.isDebug() == false) {
			final ModelAndView mav = new ModelAndView("authenticationError");
			mav.addObject("oidcAttributes", oidcAttributes);
			return mav;
		}

		final ModelAndView mav = new ModelAndView("home");
		mav.addObject("oidcAttributes", oidcAttributes);
		return mav;
	}

	// accès à la page de fourniture du service : nécessite une authentification valide
	@RequestMapping(value = "/user", method = RequestMethod.GET)
	@PreAuthorize("isFullyAuthenticated()")
	public ModelAndView user(final Principal p) {
		Tools.log("accès à /user", logger);

		// si le mode debug n'est pas positionné, seul l'IdP est activé
		if (oidcAttributes.isDebug() == false) {
			final ModelAndView mav = new ModelAndView("authenticationError");
			mav.addObject("oidcAttributes", oidcAttributes);
			return mav;
		}

		final Authentication auth = SecurityContextHolder.getContext().getAuthentication();
		final OIDCAuthenticationToken oidcauth = (OIDCAuthenticationToken) auth;

		// exemples d'accès en Java aux informations d'authentification :
		//   oidcauth.getIdToken().getJWTClaimsSet().getIssuer()
		//   oidcauth.getUserInfo().getAddress().getPostalCode()
		
		final ModelAndView mav = new ModelAndView("user");

		// On injecte dans le modèle les champs de userinfo qui ne sont pas dans le standard OpenID Connect
	    // mais néanmoins transportés dans les identités FranceConnect, car la variable userinfo
	    // automatiquement insérée dans le modèle par MitreID Connect ne contient pas de getter
	    // pour ces champs. Il s'agit uniquement de birthplace et birthcountry.
		mav.addObject("oidcBirthplace", oidcauth.getUserInfo().getSource().get("birthplace"));
		mav.addObject("oidcBirthcountry", oidcauth.getUserInfo().getSource().get("birthcountry"));

		// on injecte dans le modèle les paramètres de configuration, notamment pour le bouton FranceConnect
		mav.addObject("oidcAttributes", oidcAttributes);

		return mav;
	}

	// ne pas montrer les causes d'erreurs aux utilisateurs
	@RequestMapping(value = "/authenticationError", method = RequestMethod.GET)
	public ModelAndView authenticationError() {
		final ModelAndView mav = new ModelAndView("authenticationError");
		mav.addObject("oidcAttributes", oidcAttributes);
		return mav;
	}

	// implémentation d'un IdP
	@RequestMapping(value = "/idp", method = RequestMethod.GET)
	@PreAuthorize("isFullyAuthenticated()")
	public RedirectView idp(final HttpServletRequest request) {
		final RedirectView redirectView = new RedirectView();
		
		Tools.log("accès à /idp", logger);

		String ciphertext_hex = request.getParameter("msg");
		Tools.log("accès à /idp: requête chiffrée [" + ciphertext_hex + "]", logger);
		if (ciphertext_hex == null) {
			Tools.log("accès à /idp: renvoi vers la page d'erreur d'authentification", logger);
			redirectView.setUrl("/authenticationError");
		    return redirectView;
		}

		final String KEY = oidcAttributes.getIdpKey();
		final String IV = oidcAttributes.getIdpIv();

		try {
			final byte [] ciphertext = Hex.decodeHex(ciphertext_hex.toCharArray());
		
			// on décrypte la requête
			final PaddedBufferedBlockCipher aes = new PaddedBufferedBlockCipher(new CBCBlockCipher(new AESEngine()), new PKCS7Padding());
			final CipherParameters ivAndKey = new ParametersWithIV(new KeyParameter(Hex.decodeHex(KEY.toCharArray())), Hex.decodeHex(IV.toCharArray()));
			aes.init(false, ivAndKey);
			final int minSize = aes.getOutputSize(ciphertext.length);
			final byte [] outBuf = new byte[minSize];
			int length1 = aes.processBytes(ciphertext, 0, ciphertext.length, outBuf, 0);
			int length2 = aes.doFinal(outBuf, length1);
			final String plaintext = new String(outBuf, 0, length1 + length2, Charset.forName("UTF-8"));
			URL url = new URL(plaintext);
			Tools.log("accès à /idp: requête déchiffrée [" + url + "]", logger);

			// on récupère les paramètres nonce et state de l'URL de callback
			// s'ils sont présents plusieurs fois, on ne récupère que leurs premières instances respectives
			if (url.getQuery() == null) {
				Tools.log("accès à /idp: renvoi vers la page d'erreur d'authentification (null query)", logger);
				redirectView.setUrl("/authenticationError");
			    return redirectView;
			}

			if (plaintext.startsWith(oidcAttributes.getIdpRedirectUri()) == false) {
				Tools.log("accès à /idp: renvoi vers la page d'erreur d'authentification (url de callback invalide)", logger);
				redirectView.setUrl("/authenticationError");
			    return redirectView;
			}

			String nonce = null;
			String state = null;
			final List<NameValuePair> params = URLEncodedUtils.parse(url.getQuery(), Charset.forName("UTF-8"));
			for (final NameValuePair param : params) {
				if (nonce == null && param.getName().equals("nonce")) nonce = param.getValue();
				if (state == null && param.getName().equals("state")) state = param.getValue();
				if (nonce != null && state != null) break;
			}

			// nonce et state sont des paramètres obligatoires
			// nonce : anti-rejeu
			// state : protection contre le saut de session
			if (nonce == null) {
				Tools.log("accès à /idp: renvoi vers la page d'erreur d'authentification (null nonce)", logger);
				redirectView.setUrl("/authenticationError");
			    return redirectView;
			}
			if (state == null) {
				Tools.log("accès à /idp: renvoi vers la page d'erreur d'authentification (null state)", logger);
				redirectView.setUrl("/authenticationError");
			    return redirectView;
			}
			
			// on récupère l'identité de l'utilisateur et on y rajoute les paramètres nonce et state
			final Authentication auth = SecurityContextHolder.getContext().getAuthentication();
			final OIDCAuthenticationToken oidcauth = (OIDCAuthenticationToken) auth;
			final JsonObject gson = oidcauth.getUserInfo().toJson();
			gson.addProperty("nonce", nonce);
			gson.addProperty("state", state);
			final String info = gson.toString();
			final byte [] info_plaintext = info.getBytes();

			// on encrypte l'identité de l'utilisateur
			aes.init(true, ivAndKey);
			final byte [] inputBuf = new byte[aes.getOutputSize(info_plaintext.length)];
			length1 = aes.processBytes(info_plaintext, 0, info_plaintext.length, inputBuf, 0);
			length2 = aes.doFinal(inputBuf, length1);
			final byte [] info_ciphertext = ArrayUtils.subarray(inputBuf, 0, length1 + length2);
			final String info_ciphertext_hex = new String(Hex.encodeHex(info_ciphertext));

			// on construit l'URL vers laquelle on redirige le navigateur en ajoutant l'identité chiffrée à l'URL de callback indiquée dans la requête
			final String return_url;
			if (url.getQuery() == null || url.getQuery().isEmpty())
				return_url = plaintext + "?info=" + info_ciphertext_hex;
			else
				return_url = plaintext + "&info=" + info_ciphertext_hex;

			// on redirige l'utilisateur
			Tools.log("accès à /idp: redirection [" + return_url + "]", logger);
			redirectView.setUrl(return_url);
			return redirectView;
		} catch (final Exception ex) {
			Tools.log("accès à /idp: exception [" + ex.getStackTrace() + "]", logger);
			redirectView.setUrl("/authenticationError");
		    return redirectView;
		}
	}
}
