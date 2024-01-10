package ui;

typedef SearchElement = {
	var id: String;
	var cat: ElementCategory;
	var desc: String;
	var ?ctxDesc: String;
	var onPick: Void->Void;
	var ?keywords: Array<String>;
	var ?cachedKeywords : String;
}

enum ElementCategory {
	SE_Definition;
	SE_World;
	SE_Level;
	SE_Entity;
}

class CommandPalette {
	static var ME : Null<CommandPalette>;

	static var MAX_RESULTS = 20;
	static var MAX_DESC_LEN = 40;

	public var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	public var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;

	var jCmdPal: js.jquery.JQuery;
	var jWrapper: js.jquery.JQuery;
	var jInput: js.jquery.JQuery;
	var jResults: js.jquery.JQuery;
	var jMask: js.jquery.JQuery;
	var jElements(get,never) : js.jquery.JQuery; function get_jElements() return jResults.children(".element");
	var jCurElement(get,never) : js.jquery.JQuery; function get_jCurElement() return jElements.filter('[uid=$curUid]');

	var cleanReg = ~/[^a-z0-9 _]+/g;
	var spacesReg = ~/(  )+/g;
	var allElements : Array<SearchElement> = [];
	var curElements : Array<SearchElement> = [];
	var curUid : Null<String>;

	public function new() {
		if( ME!=null )
			ME.close();
		ME = this;

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
		jInput.on("input", _->updateResults() );
		jInput.blur( _->jInput.focus() );
		jInput.focus();

		initSearchableElements();
		updateResults();
	}


	public static function exists() {
		return ME!=null;
	}

	public static function callAgain() {
		if( exists() )
			ME.jInput.select();
	}

	function initSearchableElements() {
		allElements = [];

		// Layer defs
		for(ld in project.defs.layers)
			allElements.push({
				id: "layer_"+ld.identifier,
				cat: SE_Definition,
				desc: ld.identifier,
				ctxDesc: "Definition",
				keywords: ["layer", ld.identifier],
				onPick: ()->{
					var p = new ui.modal.panel.EditLayerDefs();
					p.select(ld);
				},
			});

		// Entity defs
		for(ed in project.defs.entities)
			allElements.push({
				id: "entity_"+ed.identifier,
				cat: SE_Definition,
				desc: ed.identifier,
				ctxDesc: "Definition",
				keywords: ["entity", ed.identifier],
				onPick: ()->{
					var p = new ui.modal.panel.EditEntityDefs();
					p.selectEntity(ed);
				},
			});

		// Enum defs
		for(ed in project.defs.enums.concat(project.defs.externalEnums))
			allElements.push({
				id: "enum_"+ed.identifier,
				cat: SE_Definition,
				desc: ed.identifier,
				ctxDesc: "Definition",
				keywords: ["enum", ed.identifier],
				onPick: ()->{
					var p = new ui.modal.panel.EditEnumDefs();
					p.selectEnum(ed);
				},
			});

		// Tileset defs
		for(td in project.defs.tilesets)
			allElements.push({
				id: "tileset_"+td.identifier,
				cat: SE_Definition,
				desc: td.identifier,
				ctxDesc: "Definition",
				keywords: ["tileset", td.identifier],
				onPick: ()->{
					var p = new ui.modal.panel.EditTilesetDefs();
					p.selectTileset(td);
				},
			});

		// List all instances
		for(w in project.worlds) {
			// Worlds
			allElements.push({
				id: w.iid,
				cat: SE_World,
				desc: w.identifier,
				keywords: [w.identifier],
				onPick: ()->editor.selectWorld(w,true),
			});
			for(l in w.levels) {
				// Levels
				allElements.push({
					id: l.iid,
					cat: SE_Level,
					desc: l.identifier,
					ctxDesc: w.identifier,
					keywords: [ w.identifier ],
					onPick: ()->editor.selectLevel(l, true),
				});

				// Entities
				for(li in l.layerInstances)
				for(ei in li.entityInstances) {
					var searchElem : SearchElement = {
						id: ei.iid,
						cat: SE_Entity,
						desc: ei.def.identifier,
						ctxDesc: l.identifier,
						keywords: [],
						onPick: ()->{
							editor.selectLevel(l, true);
							var b = editor.levelRender.bleepEntity(ei);
							b.delayS = 0.2;
							b.remainCount = 5;
						}
					}
					allElements.push(searchElem);

					// Entity fields
					for(fi in ei.fieldInstances) {
						if( !fi.def.searchable  )
							continue;
						for(i in 0...fi.getArrayLength()) {
							if( fi.valueIsNull(i) )
								continue;
							searchElem.desc += "."+fi.getForDisplay(i);
							searchElem.keywords.push( fi.getForDisplay(i) );
						}
					}

				}
			}
		}

		// Init keywords
		for(e in allElements) {
			if( e.keywords==null )
				e.keywords = [];

			e.keywords.push( switch e.cat {
				case SE_Definition: "definition";
				case SE_World: "world";
				case SE_Level: "level";
				case SE_Entity: "entity";
			});
			e.keywords.push(e.desc.toLowerCase());
			e.cachedKeywords = cleanupKeywords( e.keywords.join(" ") );
		}
	}


	function cleanupKeywords(raw:String) {
		return raw==null
			? ""
			: spacesReg.replace( cleanReg.replace(raw.toLowerCase()," "), " " );
	}


	function keywordsMatch(keywords:String, searches:Array<String>) {
		var n = 0;
		for(search in searches)
			if( keywords.indexOf(search)>=0 )
				n++;

		return n>=searches.length;
	}


	function updateResults() {
		curElements = [];
		var raw = cleanupKeywords( jInput.val() );
		var searchParts = raw.split(" ");

		// List matches
		var i = 0;
		var tooMany = false;
		if( raw.length!=0 ) {
			for(e in allElements)
				if( keywordsMatch(e.cachedKeywords, searchParts) ) {
					curElements.push(e);
					if( i++>=MAX_RESULTS ) {
						tooMany = true;
						break;
					}
				}
		}

		// Fill results list
		jResults.empty();
		curUid = null;
		for(e in curElements) {
			var jElement = new J('<div class="element"></div>');
			var iconId = switch e.cat {
				case SE_Definition: "project";
				case SE_World: "world";
				case SE_Level: "level";
				case SE_Entity: "entity";
			}
			jElement.append('<span class="icon $iconId"></span>');
			var desc = e.desc.length>=MAX_DESC_LEN ? e.desc.substr(0,MAX_DESC_LEN-3)+"..." : e.desc;
			jElement.append('<div class="desc">$desc</div>');

			if( e.ctxDesc!=null )
				jElement.append('<div class="context">${e.ctxDesc}</div>');

			jElement.addClass(e.cat.getName());
			jElement.attr("uid", e.id);
			jElement.click(_->selectResult(e));
			jElement.mousemove( _->{
				if( curUid!=e.id )
					setCurrent(e);
			});
			jElement.appendTo(jResults);
			if( curUid==null )
				setCurrent(e);
		}

		// Too many results
		if( tooMany )
			jResults.append('<div class="more"></div>');

		if( curElements.length==0 )
			jResults.hide();
		else
			jResults.show();
	}


	function selectResult(e:SearchElement) {
		close();
		e.onPick();
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
		if( ME==this )
			ME = null;
	}
}