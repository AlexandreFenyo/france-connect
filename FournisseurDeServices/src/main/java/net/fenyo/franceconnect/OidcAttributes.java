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

// Bean de stockage des paramètres de configuration
public class OidcAttributes {
	private Boolean debug;
	private String startlogouturi;
	private String afterlogouturi;
	private String fcbuttonuri;
	private Integer sessionTimeout;
	private String idpKey;
	private String idpIv;
	private String idpRedirectUri;

	public Boolean isDebug() {
		return debug;
	}

	public void setDebug(final Boolean debug) {
		this.debug = debug;
	}

	public String getStartlogouturi() {
		return startlogouturi;
	}

	public void setStartlogouturi(final String startlogouturi) {
		this.startlogouturi = startlogouturi;
	}

	public String getAfterlogouturi() {
		return afterlogouturi;
	}

	public void setAfterlogouturi(final String afterlogouturi) {
		this.afterlogouturi = afterlogouturi;
	}

	public String getFcbuttonuri() {
		return fcbuttonuri;
	}

	public void setFcbuttonuri(final String fcbuttonuri) {
		this.fcbuttonuri = fcbuttonuri;
	}

	public Integer getSessionTimeout() {
		return sessionTimeout;
	}

	public void setSessionTimeout(final Integer sessionTimeout) {
		this.sessionTimeout = sessionTimeout;
	}

	public String getIdpKey() {
		return idpKey;
	}

	public void setIdpKey(final String idpKey) {
		this.idpKey = idpKey;
	}

	public String getIdpIv() {
		return idpIv;
	}

	public void setIdpIv(final String idpIv) {
		this.idpIv = idpIv;
	}

	public String getIdpRedirectUri() {
		return idpRedirectUri;
	}

	public void setIdpRedirectUri(final String idpRedirectUri) {
		this.idpRedirectUri = idpRedirectUri;
	}
}
