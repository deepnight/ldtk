package ui.modal.panel;

class Help extends ui.modal.Panel {
	public function new() {
		super();

		canBeClosedManually = false;
		removeMask();
		setRightAlignment();
		setAlwaysOnTop();

		// Key icons
		// jContent.find("dt").each( function(idx, e) {
		// 	var jDt = new J(e);
		// 	JsTools.parseKeysIn( jDt );
		// });

		// Videos
		// var jYouTubeTags = jContent.find("youtube");
		// jYouTubeTags.each( (idx,e)->{
		// 	var jInfos = new J(e);
		// 	var jVideo = new J('<a/>');
		// 	jVideo.insertAfter(jInfos);

		// 	var id = jInfos.attr("id");
		// 	var desc = jInfos.attr("desc");
		// 	jVideo.attr("href", 'https://youtu.be/$id');
		// 	jVideo.attr("title", desc);
		// 	jVideo.append('<img src="https://img.youtube.com/vi/$id/0.jpg" alt="$desc"/>');
		// });
		// jYouTubeTags.remove();
		// JsTools.parseComponents( jContent.find(".videos") );

		gotoMenu();
	}

	function gotoMenu() {
		loadTemplate( "help", "helpPanel", {
			appUrl: Const.HOME_URL,
			discordUrl: Const.DISCORD_URL,
			docsUrl: Const.DOCUMENTATION_URL,
			jsonUrl: Const.JSON_DOC_URL,
			app: Const.APP_NAME,
			ver: Const.getAppVersionStr(true),
		});

		jContent.find(".changelog").click( _->{
			new ui.modal.dialog.Changelog(false);
			close();
		});

		// List tutorials
		var path = JsTools.getTutorialsDir();
		App.LOG.debug("tutorialsDir="+path);
		var files = NT.readDir(path);
		var jList = jContent.find(".menu");
		for(f in files) {
			var fp = dn.FilePath.fromFile(path+"/"+f);
			if( fp.extension!="html" )
				continue;

			var jLi = new J('<li/>');
			jLi.appendTo(jList);
			var jLink = new J('<a href="#"/>');
			jLink.appendTo(jLi);
			jLink.text(fp.fileName);
			jLink.click(_->{
				// loadTutorial(fp);
				new ui.Tutorial(fp);
				close();
			});
		}
	}
}
