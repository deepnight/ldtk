package ui.palette;

class EntityPalette extends ui.ToolPalette {
	var allTagGroups: Array<{ tag:Null<String>, all:Array<data.def.EntityDef> }>;
	var searchMemory : Null<String>;
	var search : QuickSearch;

	public function new(t) {
		super(t);
		jContent.addClass("entities");
	}

	override function doRender() {
		super.doRender();

		jContent.empty();

		var tool : tool.lt.EntityTool = cast tool;

		jList = new J('<ul class="niceList"/>');
		jList.appendTo(jContent);

		var jTopBar = new J('<div class="bar"/>');
		jTopBar.prependTo(jContent);

		search = new ui.QuickSearch(jList);
		search.jWrapper.appendTo(jTopBar);


		// View select
		var stateId = App.ME.settings.makeStateId(EntityPaletteColumns, editor.curLayerDef.uid);
		var columns = App.ME.settings.getUiStateInt(stateId, project, 1);
		JsTools.removeClassReg(jList, ~/col-[0-9]+/g);
		jList.addClass("col-"+columns);
		var jMode = new J('<button class="transparent displayMode"> <span class="icon gridView"></span> </button>');
		jMode.appendTo(jTopBar);
		jMode.off().click(_->{
			var m = new ui.modal.ContextMenu(jMode);
			m.addAction({
				label:L.t._("List"),
				iconId: "listView",
				cb: ()->{
					App.ME.settings.deleteUiState(stateId, project);
					doRender();
				}
			});
			for(n in [2,3,4,5,6,7,8,9,10]) {
				m.addAction({
					label:L.t._("::n:: columns", {n:n}),
					iconId: "gridView",
					cb: ()->{
						App.ME.settings.setUiStateInt(stateId, n, project);
						doRender();
					}
				});
			}
		});


		var ld = Editor.ME.curLayerDef;
		allTagGroups = project.defs.groupUsingTags(
			project.defs.entities,
			(ed)->ed.tags,
			(ed)->!ed.tags.hasAnyTagFoundIn(ld.excludedTags) && ( ld.requiredTags.isEmpty() || ed.tags.hasAnyTagFoundIn(ld.requiredTags) )
		);

		var groupIdx = 0;
		var y = 0;
		for(group in allTagGroups) {
			// Tag header
			if( allTagGroups.length>1 && group.all.length>0 ) {
				var jTag = new J('<li class="title collapser"/>');
				jTag.appendTo(jList);
				jTag.text( group.tag==null ? L._Untagged() : group.tag );
				jTag.attr("id", project.iid+"_entityPalette_"+ld.uid+"_tag_"+group.tag);
				jTag.attr("default", "open");
			}

			var jLi = new J('<li class="subList"> <ul class="niceList"/> </li>');
			jLi.attr("data-groupIdx", Std.string(groupIdx));
			jLi.appendTo(jList);
			var jSubList = jLi.find("ul");

			for(ed in group.all) {
				var jLi = new J("<li/>");
				jLi.appendTo(jSubList);
				jLi.attr("data-defUid", ed.uid);
				jLi.attr("data-y", Std.string(y));
				jLi.addClass("entity");
				jLi.css( "border-color", C.intToHex(ed.color) );
				jLi.css("background-color", dn.Col.fromInt(ed.color).toCssRgba(0.4));

				if( ed.doc!=null ) {
					jLi.attr("tip", "right");
					Tip.attach(jLi, ed.doc);
				}

				// State
				if( ed==tool.curEntityDef ) {
					jLi.addClass("active");
					jLi.css( "background-color", makeBgActiveColor(ed.color) );
				}
				else {
					jLi.css( "background-color", makeBgInactiveColor(ed.color) );
					jLi.css( "color", makeTextInactiveColor(ed.color) );
				}

				// Preview and label
				var jPreview = JsTools.createEntityPreview(Editor.ME.project, ed);
				jPreview.addClass("notCompact");
				jLi.append(jPreview);
				jLi.append('<span class="name">${ed.identifier}</span>');

				jLi.mousedown( function(_) {
					if( Editor.ME.isPaused() )
						return;
					tool.selectValue(ed.uid);
					render();
				});

				var actions : Array<ui.modal.ContextMenu.ContextAction> = [
					{
						 label: L.t._("Edit entity definition"),
						 cb: ()->new ui.modal.panel.EditEntityDefs(ed),
					},
				];
				ui.modal.ContextMenu.attachTo(jLi, false, actions);

				y++;
			}

			groupIdx++;
		}

		JsTools.parseComponents(jList);

		if( searchMemory!=null )
			search.run(searchMemory);
		search.onSearch = (s)->searchMemory = s;
	}

	override function onHide() {
		super.onHide();
		search.clear();
	}


	override function onNavigateSelection(dx:Int, dy:Int, pressed:Bool):Bool {
		// Search current selection position
		var tool : tool.lt.EntityTool = cast tool;
		var groupIdx = 0;
		var selY = 0;
		var found = false;
		for(group in allTagGroups) {
			for(ed in group.all)
				if( ed==tool.curEntityDef ) {
					found = true;
					break;
				}
				else
					selY++;

			if( found )
				break;
			else
				groupIdx++;
		}

		if( dy!=0 ) {
			// Prev/next item
			selY+=dy;
			jContent.find('[data-y=$selY]').mousedown();
			focusOnSelection(true);
		}
		else if( dx!=0 ) {
			// Prev/next tag group
			if( dx<0 && !jContent.find("li.active").is('[data-groupIdx=$groupIdx] li:first') ) {
				jContent.find('[data-groupIdx=$groupIdx] li:first').mousedown();
				focusOnSelection(true);
				return true;
			}
			else if( dx>0 && groupIdx==allTagGroups.length-1 ) {
				jContent.find('[data-groupIdx=$groupIdx] li:last').mousedown();
				focusOnSelection(true);
				return true;
			}
			else {
				groupIdx+=dx;
				jContent.find('[data-groupIdx=$groupIdx] li:first').mousedown();
				focusOnSelection(true);
				return true;
			}
		}
		return false;
	}


	override function focusOnSelection(immediate=false) {
		super.focusOnSelection(immediate);

		// Focus scroll animation
		var e = jList.find('[data-defUid=${tool.getSelectedValue()}]');
		if( e.length>0 ) {
			animateListScrolling( e.position().top + e.outerHeight()*0.5 );
			if( immediate )
				jList.scrollTop(listTargetY);
		}
	}
}