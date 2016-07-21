package net.fenyo.franceconnect;

public class OidcAttributes {
	private String startlogouturi;
	private String fcbuttonuri;
	private Integer sessionTimeout;
	
	public String getStartlogouturi() {
		return startlogouturi;
	}

	public void setStartlogouturi(final String startlogouturi) {
		this.startlogouturi = startlogouturi;
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
}
