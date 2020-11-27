package ui.modal.panel;

class Help extends ui.modal.Panel {
	public function new() {
		super();

		loadTemplate( "help", "helpPanel", {
			appUrl: Const.HOME_URL,
			discordUrl: Const.DISCORD_URL,
			docUrl: Const.DOCUMENTATION_URL,
			app: Const.APP_NAME,
			ver: Const.getAppVersion(),
		});

		jContent.find("dt").each( function(idx, e) {
			var jDt = new J(e);
			var jKeys = JsTools.parseKeys( jDt.text() );
			jDt.empty().append(jKeys);
		});
	}

}
