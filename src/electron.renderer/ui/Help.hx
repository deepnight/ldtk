package ui;

class Help extends dn.Process {
	var jWrapper : js.jquery.JQuery;
	var jContent : js.jquery.JQuery;

	public function new() {
		super();

		jWrapper = new J('<div class="helpBar"/>');
		App.ME.jPage.append(jWrapper);

		jContent = new js.jquery.JQuery('<div class="wrapper"/>');
		jContent.appendTo(jWrapper);

		// Main page
		loadTemplate( "help", "helpPanel", {
			appUrl: Const.HOME_URL,
			discordUrl: Const.DISCORD_URL,
			docsUrl: Const.DOCUMENTATION_URL,
			jsonUrl: Const.JSON_DOC_URL,
			app: Const.APP_NAME,
			ver: Const.getAppVersionStr(),
		});

		jContent.find(".changelog").click( _->{
			new ui.modal.dialog.Changelog(false);
			close();
		});

		// Key icons
		jContent.find("dt").each( function(idx, e) {
			var jDt = new J(e);
			JsTools.parseKeysIn( jDt );
		});
	}

	public function close() {
		jWrapper.remove();
		destroy();
	}

	function loadTemplate(tplName:String, ?className:String, ?vars:Dynamic, useCache=true) {
		if( className==null )
			className = StringTools.replace(tplName, ".html", "");

		jWrapper.addClass(className);
		var html = JsTools.getHtmlTemplate(tplName, vars, useCache);
		jContent.empty().off().append( html );
		JsTools.parseComponents(jContent);
		ui.Tip.clear();
	}
}
