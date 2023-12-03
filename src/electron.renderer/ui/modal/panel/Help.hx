package ui.modal.panel;

enum TutorialTarget {
	T_Unknown;
	T_Window(id:String, buttonSelector:Null<String>, windowSelector:String);
	T_Selector(selector:String);
}

// typedef TutorialStep = {
// 	var targets : Array<TutorialTarget>;
// 	var defaultDesc : Null<String>;
// }

class Help extends ui.modal.Panel {
	var curStep = -1;
	var jTutorialData : Null<js.jquery.JQuery>;

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


	function parseTargets(rawAttr:String) : Array<TutorialTarget> {
		var out = [];
		var rawTargets = rawAttr.split("|");

		for(rawTarget in rawTargets) {
			var targetType = StringTools.trim( rawTarget.split(":")[0] );
			var targetParam = StringTools.trim( rawTarget.split(":")[1] );
			out.push(switch targetType {
				case "panel":
					switch targetParam {
						case "project": T_Window(targetParam, ".editProject", ".window.editProject");
						case "level": T_Window(targetParam, ".editLevelInstance", ".window.levelInstancePanel");
						case "layers": T_Window(targetParam, ".editLayers", ".window.editLayerDefs");
						case "entities": T_Window(targetParam, ".editEntities", ".window.entityDefs");
						case "tileset": T_Window(targetParam, ".editTilesets", ".window.editTilesetDefs");
						case "enums": T_Window(targetParam, ".editEnums", ".window.editEnumDefs");
						case _: T_Unknown;
					}

				case "class": T_Selector("."+targetParam);
				case "selector": T_Selector(targetParam);
				case _: T_Unknown;
			});
		}

		return out;
	}



	function loadTutorial(fp:dn.FilePath) {
		jContent.empty();

		var html = NT.readFileString(fp.full);
		jTutorialData = new J('<div class="tutorialData"/>');
		jTutorialData.append(html);
		var jStepList = new J('<ol/>');

		function _cleanup(str:String) : Null<String> {
			return str==null ? null : StringTools.trim(str);
		}

		function _err(?str:String) {
			return '<div class="error">${str!=null?str:"Error"}</div>';
		}

		// Check requirements
		var jRequire = jTutorialData.find("require");

		// Grab steps
		var jSteps = jTutorialData.find("step");
		var stepIdx = 0;
		jSteps.each((idx,e)->{
			var jStep = new J(e);

			// Parse step info
			var targets = parseTargets( jStep.attr("target") );
			// var rawData = jStep.attr("target");
			// var targets = rawData.split("|");
			var desc = StringTools.trim( jStep.text() );

			// Try to fix empty desc
			if( desc=="" )
				for(target in targets) {
					switch target {
						case T_Unknown:

						case T_Window(id, _):
							var name = switch id {
								case "layers": "Layers";
								case "entities": "Entities";
								case "enums": "Enums";
								case "tilesets": "Tilesets";
								case "project": "Project Settings";
								case "world": "World";
								case "level": "Level Settings";
								case _: null;
							}
							if( name!=null ) {
								desc = 'Open the $name panel';
								break;
							}

						case T_Selector(selector):
							desc = "Click at this UI element.";
							break;
					}
				}

			// Create tutorial step element
			var jLi = new J('<li>$desc</li>');
			jLi.appendTo(jStepList);
			jLi.attr("stepIdx", Std.string(stepIdx));
			jLi.attr("target", jStep.attr("target"));

			stepIdx++;
		});


		// Build page
		var jTutorialPage = new J('<div class="tutorial"/>');
		jTutorialPage.appendTo(jContent);

		var jIntro = jTutorialData.find("intro");
		jTutorialPage.append( jIntro.children().wrapAll('<div class="intro"></div>') );
		jStepList.appendTo(jTutorialPage);

		jContent.append(jTutorialData);
		jTutorialData.hide();

		activateStep(0);
	}


	function highlight(jElement:js.jquery.JQuery) {
		var jHighlight = new J('<div class="tutorialHighlighter"></div>');
		App.ME.jPage.append(jHighlight);

		var off = jElement.offset();
		var pad = 3;
		jHighlight.css({
			top: (off.top-pad)+"px",
			left: (off.left-pad)+"px",
			width: (jElement.outerWidth()+pad*2)+"px",
			height: (jElement.outerHeight()+pad*2)+"px",
		});
	}


	function clearTutorialStep() {
		App.ME.jPage.find('.tutorialHighlighter').remove();
		App.ME.jPage.find('*').off(".tutorialClickTrap");
	}

	function activateStep(idx) {
		var jPage = App.ME.jPage;

		curStep = idx;
		jContent.find('li[stepIdx]').removeClass("active");

		var jStep = jContent.find('li[stepIdx=$curStep]');
		jStep.addClass("active");

		// Cleanup
		clearTutorialStep();

		// Point targets
		var targets = parseTargets(jStep.attr("target"));
		trace(curStep);
		trace(targets);
		for(t in targets) {
			switch t {
				case T_Unknown:
					stepChecker = ()->return false;

				case T_Window(id, buttonSelector, windowSelector):
					highlight( jPage.find(buttonSelector) );
					stepChecker = ()->return jPage.find(windowSelector).length>0;

				case T_Selector(selector):
					var jElement = jPage.find(selector);
					highlight(jElement);
					jElement.on("click.tutorialClickTrap", _->{
						nextStep();
					});
					stepChecker = ()->return false;
			}
		}
	}

	dynamic function stepChecker() {
		return false;
	}

	function nextStep() {
		curStep++;
		clearTutorialStep();
		cd.setS("tutorialLock",0.2);
		delayer.addS(activateStep.bind(curStep), 0.2);
	}

	override function update() {
		super.update();

		if( curStep>=0 && !cd.hasSetS("check",0.1) && !cd.has("tutorialLock") ) {
			if( stepChecker() )
				nextStep();
		}
	}
}
