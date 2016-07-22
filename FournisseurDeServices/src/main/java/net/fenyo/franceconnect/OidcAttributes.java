package net.fenyo.franceconnect;

// Bean de stockage des paramètres de configuration
public class OidcAttributes {
	private Boolean debug;
	private String startlogouturi;
	private String afterlogouturi;
	private String fcbuttonuri;
	private Integer sessionTimeout;
	private String idpKey;
	private String idpIv;

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
}
