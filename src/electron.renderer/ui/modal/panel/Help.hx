package ui.modal.panel;

class Help extends ui.modal.Panel {
	var curStep = 0;

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
				loadTutorial(fp);
			});
		}
	}

	function loadTutorial(fp:dn.FilePath) {
		unloadTemplate();
		var html = NT.readFileString(fp.full);
		jContent.html(html);

		function _cleanup(str:String) : Null<String> {
			return str==null ? null : StringTools.trim(str);
		}

		function _err(?str:String) {
			return '<div class="error">${str!=null?str:"Error"}</div>';
		}

		var jSteps = jContent.find("ol>li");
		var stepIdx = 0;
		jSteps.each((idx,e)->{
			var jStep = new J(e);
			jStep.attr("stepIdx", Std.string(stepIdx));
			jStep.click(_->gotoMenu()); // HACK

			// Parse step
			var rawData = jStep.attr("step");
			var targets = rawData.split("|");
			var first = true;
			for(target in targets) {
				var targetType = _cleanup( target.split(":")[0] );
				var targetInfo = _cleanup( target.split(":")[1] );
				// jStep.text(targetType+" => "+targetInfo);

				if( first && jStep.text()=="" )
					jStep.text( switch targetType {
						case "panel":
							var name = switch targetInfo {
								case "layers": "Layers";
								case "entities": "Entities";
								case "enums": "Enums";
								case "tilesets": "Tilesets";
								case "project": "Project Settings";
								case "world": "World";
								case "level": "Level Settings";
								case _: _err("Unknown panel "+targetInfo);
							}
							'Open the $name panel';
						case _: _err("Missing text");
					});

				first = false;
			}

			if( jStep.text()=="" )
				jStep.text("-filler-");
			stepIdx++;
		});

		activateStep(0);
	}

	function activateStep(idx) {
		curStep = idx;
		jContent.find('li[stepIdx]').removeClass("active");
		jContent.find('li[stepIdx=$curStep]').addClass("active");
	}
}
