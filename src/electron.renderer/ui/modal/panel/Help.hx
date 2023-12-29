package ui.modal.panel;

class Help extends ui.modal.Panel {
	public function new() {
		super();

		// Main page
		linkToButton("button.showHelp");
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
		function _getFirstRelevantBinding(rawCmdId:String) : Null<KeyBinding> {
			rawCmdId = rawCmdId.toLowerCase();
			for(kb in App.ME.keyBindings)
				if( kb.command.getName().toLowerCase().substr(2)==rawCmdId )
					switch kb.os {
						case null: return kb;
						case "win": if( App.isWindows() ) return kb;
						case "mac": if( App.isMac() ) return kb;
						case "linux": if( App.isLinux() ) return kb;
					}

			return null;
		}
		jContent.find("dt").each( function(idx, e) {
			var jDt = new J(e);
			var raw = jDt.text();
			var rawCmdExpr = ~/%([a-z_0-9]+)%/gi;
			if( rawCmdExpr.match(raw) ) {
				var kb = _getFirstRelevantBinding(rawCmdExpr.matched(1));
				jDt.text( kb==null ? '?{$rawCmdExpr.matched(1)}?' : kb.jsDisplayText );
			}
			var jKeys = JsTools.parseKeysIn( jDt );
			jDt.empty().append( jKeys );
		});

		// Videos
		var jYouTubeTags = jContent.find("youtube");
		jYouTubeTags.each( (idx,e)->{
			var jInfos = new J(e);
			var jVideo = new J('<a/>');
			jVideo.insertAfter(jInfos);

			var id = jInfos.attr("id");
			var desc = jInfos.attr("desc");
			jVideo.attr("href", 'https://youtu.be/$id');
			jVideo.attr("title", desc);
			jVideo.append('<img src="https://img.youtube.com/vi/$id/0.jpg" alt="$desc"/>');
		});
		jYouTubeTags.remove();
		JsTools.parseComponents( jContent.find(".videos") );
	}

}
