package ui;

typedef SearchElement = {
	var id: String;
	var cat: ElementCategory;
	var desc: String;
	var onPick: Void->Void;
	var ?keywords: String;
}

enum ElementCategory {
	SE_World;
	SE_Level;
	SE_Entity;
}

class CommandPalette {
	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jCmdPal: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	var jInput: js.jquery.JQuery;
	var jResults: js.jquery.JQuery;
	var jMask: js.jquery.JQuery;
	var jElements(get,never) : js.jquery.JQuery; function get_jElements() return jResults.children(".element");
	var jCurElement(get,never) : js.jquery.JQuery; function get_jCurElement() return jElements.filter('[uid=$curUid]');

	var cleanReg = ~/[^a-z0-9 _]+/gi;
	var allElements : Array<SearchElement> = [];
	var curElements : Array<SearchElement> = [];
	var curUid : Null<String>;

	public function new() {
		var jXml = App.ME.jPage.find("xml.commandPalette");
		jCmdPal = jXml.children().clone().wrapAll('<div id="commandPalette"></div>').parent();
		App.ME.jPage.append(jCmdPal);

		jMask = jCmdPal.find(".mask");
		jWrapper = jCmdPal.find(".wrapper");
		jInput = jCmdPal.find("input[type=text]");
		jResults = jCmdPal.find(".results");

		jMask.click(_->close());

		jInput.keydown( (ev:js.jquery.Event)->{
			switch ev.key {
				case "Escape": close();
				case "ArrowUp": moveCurrent(-1);
				case "ArrowDown": moveCurrent(1);
				case "Enter":
					if( curUid!=null )
						jCurElement.click();
				case _:
			}
		});
		jInput.on("input", _->applySearch() );
		jInput.blur( _->jInput.focus() );
		jInput.focus();

		// List all elements
		for(w in project.worlds) {
			// Worlds
			allElements.push({
				id: w.iid,
				cat: SE_World,
				desc: w.identifier,
				onPick: ()->editor.selectWorld(w,true),
			});
			for(l in w.levels) {
				// Levels
				allElements.push({
					id: l.iid,
					cat: SE_Level,
					desc: l.identifier,
					onPick: ()->editor.selectLevel(l, true),
				});

				for(li in l.layerInstances)
				for(e in li.entityInstances) {
					allElements.push({
						id: e.iid,
						cat: SE_Entity,
						desc: e.def.identifier+"#"+e.defUid,
						onPick: ()->{
							editor.selectLevel(l, true);
						}
					});
				}
			}
		}

		// Init keywords
		for(e in allElements) {
			e.keywords = switch e.cat {
				case SE_World: "world";
				case SE_Level: "level";
				case SE_Entity: "entity";
			}
			e.keywords += " "+e.desc.toLowerCase();
			e.keywords = cleanupKeywords(e.keywords);
		}

		applySearch();
	}


	function cleanupKeywords(raw:String) {
		return raw==null ? "" : cleanReg.replace(raw, " ").toLowerCase();
	}


	function applySearch() {
		curElements = [];
		var raw = cleanupKeywords( jInput.val() );

		// List matches
		for(e in allElements)
			if( e.keywords.indexOf(raw)>=0 )
				curElements.push(e);

		// Fill results list
		jResults.empty();
		curUid = null;
		var i = 0;
		for(e in curElements) {
			var jElement = new J('<div class="element">${e.desc}</div>');
			var iconId = switch e.cat {
				case SE_World: "world";
				case SE_Level: "level";
				case SE_Entity: "entity";
			}
			jElement.prepend('<span class="icon $iconId"></span>');
			var col = switch e.cat {
				case SE_World: "#ad8358";
				case SE_Level: "#70a9ff";
				case SE_Entity: "#ff9900";
			}
			jElement.css("color", col);
			jElement.attr("uid", e.id);
			jElement.click(_->{
				close();
				e.onPick();
			});
			jElement.mousemove( _->{
				if( curUid!=e.id )
					setCurrent(e);
			});
			jElement.appendTo(jResults);
			if( curUid==null )
				setCurrent(e);

			if( i++>=15 ) {
				jResults.append('<div class="more"></div>');
				break;
			}
		}
	}


	function moveCurrent(delta:Int) {
		var jCur = jElements.filter('[uid=$curUid]');
		if( jCur.length==0 || curUid==null )
			updateCurrent();
		else {
			if( delta<0 )
				jCur = jCur.prev();
			else
				jCur = jCur.next();
			if( jCur.length>0 ) {
				curUid = jCur.attr("uid");
				updateCurrent();
			}
		}
	}


	function setCurrent(?e:SearchElement) {
		curUid = e==null ? null : e.id;
		updateCurrent();
	}

	function updateCurrent() {
		jElements.removeClass("active");
		if( curUid!=null )
			jElements.filter('[uid=$curUid]').addClass("active");
	}

	function close() {
		jCmdPal.remove();
		jCmdPal = null;
	}
}