package ui;

enum TutorialTarget {
	T_Unknown;
	T_Window(id:String, buttonSelector:Null<String>, windowSelector:String);
	T_Selector(selector:String);
}

typedef TutorialStep = {
	var desc : String;
	var targets : Array<TutorialTarget>;
	var completeCond : Void->Bool;
}

class Tutorial extends dn.Process {
	var jPage(get,never) : js.jquery.JQuery; inline function get_jPage() return App.ME.jPage;

	var curStepIdx = 0;
	var curStep(get,never) : TutorialStep; inline function get_curStep() return steps[curStepIdx];
	var steps : Array<TutorialStep> = [];

	public function new(fp:dn.FilePath) {
		super(Editor.ME);

		// Load tutorial file
		var html = NT.readFileString(fp.full);
		var jTutorialData = new J(html);

		// Check requirements
		var jRequire = jTutorialData.filter("require");
		// TODO check requirements

		// Read steps
		var jSteps = jTutorialData.filter("step");
		var stepIdx = 0;
		jSteps.each((idx,e)->{
			var jStep = new J(e);

			// Parse step info
			var targets = parseTargetsAttr( jStep.attr("target") );
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
			var step : TutorialStep = {
				desc: desc,
				targets: targets,
				completeCond: ()->return false,
			}
			steps.push(step);
			// var jLi = new J('<li>$desc</li>');
			// jLi.appendTo(jStepList);
			// jLi.attr("stepIdx", Std.string(stepIdx));
			// jLi.attr("target", jStep.attr("target"));

			stepIdx++;
		});

		activateStep(0);
	}


	function parseTargetsAttr(rawAttr:String) : Array<TutorialTarget> {
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


	function highlight(jElement:js.jquery.JQuery) {
		var jHighlight = new J('<div class="tutorialHighlighter"></div>');
		jPage.append(jHighlight);

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
		jPage.find(".tutorialDesc").remove();
		jPage.find('.tutorialHighlighter').remove();
		jPage.find('*').off(".tutorialClickTrap");
	}

	function activateStep(idx) {
		clearTutorialStep();
		curStepIdx = idx;

		// Point targets
		for(t in curStep.targets) {
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

		// Add desc
		var jDesc = new J('<div class="tutorialDesc"/>');
		jPage.append(jDesc);
		jDesc.append(curStep.desc);
		var jNear = jPage.find(".tutorialHighlighter:first");

		var docWid = App.ME.jDoc.innerWidth();
		var docHei = App.ME.jDoc.innerHeight();
		var x = jNear.offset().left;
		var y = jNear.offset().top;
		var distPx = 30;

		if( x<docWid*0.5 )
			x+=distPx;
		else
			x-=distPx;

		if( y<docHei*0.5 )
			y += jNear.outerHeight() + distPx;
		else
			y -= jDesc.outerHeight() - distPx;

		jDesc.offset({ left:x, top:y });
	}

	dynamic function stepChecker() {
		return false;
	}

	function nextStep() {
		clearTutorialStep();
		cd.setS("tutorialLock",0.2);
		delayer.addS(activateStep.bind(curStepIdx+1), 0.2);
	}

	override function update() {
		super.update();

		if( curStepIdx>=0 && !cd.hasSetS("check",0.1) && !cd.has("tutorialLock") ) {
			if( stepChecker() )
				nextStep();
		}
	}
}