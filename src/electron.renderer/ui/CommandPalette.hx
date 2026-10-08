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
	SE_LevelField;
	SE_Layer;
	SE_Entity;
	SE_EntityField;
}

class CommandPalette {
	static var ME : Null<CommandPalette>;

	static var LAST_SEARCH : String = null;
	static var MAX_RESULTS = 20;

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
		jInput.on("input", _->updateResults(false) );
		jInput.blur( _->jInput.focus() );
		if( LAST_SEARCH!=null )
			jInput.val(LAST_SEARCH);
		jInput.focus();
		jInput.select();

		initSearchableElements();
		updateResults(false);
	}


	public static function exists() {
		return ME!=null;
	}

	public static function callAgain() {
		if( exists() )
			ME.jInput.select();
	}


	// Create a full list of everything that is searchable in the project
	function initSearchableElements() {
		allElements = [];

		// Layer defs
		for(ld in project.defs.layers)
			allElements.push({
				id: "layer_"+ld.identifier,
				cat: SE_Definition,
				desc: ld.identifier,
				ctxDesc: "Definition",
				keywords: [ld.identifier],
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
				keywords: [ed.identifier],
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
				keywords: [ed.identifier],
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
				keywords: [td.identifier],
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
				keywords: [w.identifier, w.iid],
				onPick: ()->editor.selectWorld(w,true),
			});
			for(l in w.levels) {
				// Levels
				allElements.push({
					id: l.iid,
					cat: SE_Level,
					desc: "Level "+l.identifier,
					ctxDesc: w.identifier,
					keywords: [ l.identifier, w.identifier, l.iid ],
					onPick: ()->editor.selectLevel(l, true),
				});

				// Level fields
				for(fi in l.fieldInstances) {
					if( !fi.def.searchable )
						continue;

					for(i in 0...fi.getArrayLength())
						if( !fi.valueIsNull(i) )
							allElements.push({
								id: l.iid+"_field_"+fi.defUid,
								cat: SE_LevelField,
								desc: l.identifier+"."+fi.getForDisplay(i),
								ctxDesc: l.identifier,
								keywords: [ fi.getForDisplay(i) ],
								onPick: ()->{
									editor.selectLevel(l, true);
									new ui.modal.panel.LevelInstancePanel();
								},
							});
				}

				// Layer instances
				for(li in l.layerInstances)
					allElements.push({
						id: li.iid,
						cat: SE_Layer,
						desc: "Layer "+li.def.identifier,
						ctxDesc: l.identifier,
						keywords: [ li.iid ],
						onPick: ()->{
							editor.selectLevel(l, true);
							editor.selectLayerInstance(li);
						},
					});

				// Entities
				for(li in l.layerInstances)
				for(ei in li.entityInstances) {
					var searchElem : SearchElement = {
						id: ei.iid,
						cat: SE_Entity,
						desc: ei.def.identifier,
						ctxDesc: l.identifier,
						keywords: [ ei.def.identifier, ei.iid ],
						onPick: ()->{
							editor.selectLevel(l, true);
							var b = editor.levelRender.bleepEntity(ei);
							b.delayS = 0.2;
							b.remainCount = 5;
						}
					}
					allElements.push(searchElem);

					for(fi in ei.fieldInstances) {
						if( !fi.def.searchable  )
							continue;

						// Append entity fields to the entity name
						for(i in 0...fi.getArrayLength())
							if( !fi.valueIsNull(i) )
								searchElem.desc += "."+fi.getForDisplay(i);

						// Make individual entity fields searchable
						for(i in 0...fi.getArrayLength()) {
							if( fi.valueIsNull(i) )
								continue;

							allElements.push({
								id: ei.iid+"_field_"+fi.defUid,
								cat: SE_EntityField,
								desc: ei.def.identifier+"."+fi.getForDisplay(i),
								ctxDesc: ei.def.identifier,
								keywords: [ fi.getForDisplay(i) ],
								onPick: ()->{
									editor.selectLevel(l, true);
									var b = editor.levelRender.bleepEntity(ei);
									b.delayS = 0.2;
									b.remainCount = 5;
								},
							});
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
				case SE_LevelField: "level field";
				case SE_Layer: "layer";
				case SE_Entity: "entity";
				case SE_EntityField: "entity field";
			});
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


	function updateResults(showAll:Bool) {
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
					if( !showAll && i++>=MAX_RESULTS ) {
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
				case SE_LevelField: "list";
				case SE_Layer: "layer";
				case SE_Entity: "entity";
				case SE_EntityField: "list";
			}
			jElement.append('<span class="icon $iconId"></span>');

			var typeDesc = switch e.cat {
				case SE_Definition: "Def";
				case SE_World: "World";
				case SE_Level: "Level";
				case SE_LevelField: "LField";
				case SE_Layer: "Layer";
				case SE_Entity: "Entity";
				case SE_EntityField: "EField";
			};
			jElement.append('<span class="type">$typeDesc</span>');

			jElement.append( new J('<div class="desc"/>').text(e.desc) );

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
		if( tooMany && !showAll ) {
			var jMore = new J('<div class="more">Show all results</div>');
			jMore.click( _->updateResults(true) );
			jResults.append(jMore);

		}

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
		LAST_SEARCH = jInput.val();
		jCmdPal.remove();
		jCmdPal = null;
		if( ME==this )
			ME = null;
	}
}