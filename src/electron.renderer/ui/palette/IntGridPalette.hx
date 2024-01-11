package ui.palette;

class IntGridPalette extends ui.ToolPalette {
	var searchMemory : Null<String>;
	var search : QuickSearch;

	public function new(t) {
		super(t);
		jContent.addClass("intGrid");
	}

	override function doRender() {
		super.doRender();

		jContent.empty();

		jList = new J('<ul class="intGridValues niceList"/>');
		jList.appendTo(jContent);

		var jTopBar = new J('<div class="bar"/>');
		jTopBar.prependTo(jContent);

		search = new ui.QuickSearch(jList);
		search.jWrapper.appendTo(jTopBar);


		// View select
		var stateId = App.ME.settings.makeStateId(IntGridPaletteColumns, editor.curLayerDef.uid);
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

		var groups = tool.curLayerInstance.def.getGroupedIntGridValues();

		var groupIdx = 0;
		var y = 0;
		for(g in groups) {
			if( g.all.length>0 && groups.length>1 ) {
				var jTitle = new J('<li class="title collapser"/>');
				jTitle.appendTo(jList);
				jTitle.text(g.displayName);
				jTitle.attr("id", project.iid+"_intGridPalette_"+tool.curLayerInstance.layerDefUid+"_group_"+g.groupUid);
				jTitle.attr("default", "open");
			}

			var jLi = new J('<li class="subList"> <ul class="niceList"/> </li>');
			jLi.attr("data-groupIdx", Std.string(groupIdx));
			jLi.appendTo(jList);
			var jSubList = jLi.find("ul");

			for( intGridVal in g.all ) {
				var jLi = new J("<li/>");
				jLi.appendTo(jSubList);
				jLi.attr("data-id", intGridVal.value);
				jLi.attr("data-y", Std.string(y++));
				jLi.addClass("color");

				jLi.css( "border-color", C.intToHex(intGridVal.color) );

				// State
				if( intGridVal.value==tool.getSelectedValue() ) {
					jLi.addClass("active");
					jLi.css( "background-color", makeBgActiveColor(intGridVal.color) );
				}
				else {
					jLi.css( "background-color", makeBgInactiveColor(intGridVal.color) );
					jLi.css( "color", makeTextInactiveColor(intGridVal.color) );
				}

				// Value
				var jVal = JsTools.createIntGridValue(project, intGridVal, false);
				jVal.appendTo(jLi);

				// Label
				if( intGridVal.identifier!=null )
					jLi.append('<span class="name">${intGridVal.identifier}</span>');

				var curValue = intGridVal.value;
				jLi.mousedown( function(_) {
					if( Editor.ME.isPaused() )
						return;
					tool.selectValue(curValue);
					render();
				});

				ui.modal.ContextMenu.attachTo_new(jLi, false, (ctx:ui.modal.ContextMenu)->{
					ctx.addAction({
						label: L.t._("Edit layer"),
						cb: ()->{
							App.ME.executeAppCommand(C_OpenLayerPanel);
						},
					});
				});
			}

			groupIdx++;
		}

		if( searchMemory!=null )
			search.run(searchMemory);
		search.onSearch = (s)->searchMemory = s;

		JsTools.parseComponents(jList);
	}


	override function onHide() {
		super.onHide();
		search.clear();
	}


	override function focusOnSelection(immediate=false) {
		super.focusOnSelection();

		// Focus scroll animation
		var e = jList.find('[data-id=${tool.getSelectedValue()}]');
		if( e.length>0 ) {
			animateListScrolling( e.position().top + e.outerHeight()*0.5 );
			if( immediate )
				jList.scrollTop( listTargetY );
		}
	}



	override function onNavigateSelection(dx:Int, dy:Int, pressed:Bool):Bool {
		// Search current selection position
		var tool : tool.lt.IntGridTool = cast tool;
		var ld = Editor.ME.curLayerDef;
		var groupIdx = 0;
		var selY = 0;
		var groups = ld.getGroupedIntGridValues();
		var found = false;
		for(g in groups) {
			for(iv in g.all)
				if( iv.value==tool.getSelectedValue() ) {
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
			// Prev/next group
			if( dx<0 && !jContent.find("li.active").is('[data-groupIdx=$groupIdx] li:first') ) {
				jContent.find('[data-groupIdx=$groupIdx] li:first').mousedown();
				focusOnSelection(true);
				return true;
			}
			else if( dx>0 && groupIdx==groups.length-1 ) {
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

		return true;
	}


}
