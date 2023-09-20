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

		jList = new J('<ul class="intGridValues niceList"/>');
		jList.appendTo(jContent);

		search = new ui.QuickSearch(jList);
		search.jWrapper.prependTo(jContent);

		var groups = tool.curLayerInstance.def.getGroupedIntGridValues();

		var groupIdx = 0;
		var y = 0;
		for(g in groups) {
			if( g.all.length>0 && groups.length>1 ) {
				var jTitle = new J('<li class="title collapser"/>');
				jTitle.appendTo(jList);
				jTitle.text(g.displayName);
				jTitle.attr("id", project.iid+"_intGridPalette_group_"+g.groupUid);
				jTitle.attr("default", "open");
			}

			var jLi = new J('<li class="subList"> <ul/> </li>');
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
				var jVal = JsTools.createIntGridValue(project, intGridVal);
				jVal.appendTo(jLi);

				// Label
				if( intGridVal.identifier!=null )
					jLi.append(intGridVal.identifier);

				var curValue = intGridVal.value;
				jLi.click( function(_) {
					if( Editor.ME.isPaused() ) return;
					tool.selectValue(curValue);
					render();
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
			jContent.find('[data-y=$selY]').click();
			focusOnSelection(true);
		}
		else if( dx!=0 ) {
			// Prev/next group
			if( dx<0 && !jContent.find("li.active").is('[data-groupIdx=$groupIdx] li:first') ) {
				jContent.find('[data-groupIdx=$groupIdx] li:first').click();
				focusOnSelection(true);
				return true;
			}
			else if( dx>0 && groupIdx==groups.length-1 ) {
				jContent.find('[data-groupIdx=$groupIdx] li:last').click();
				focusOnSelection(true);
				return true;
			}
			else {
				groupIdx+=dx;
				jContent.find('[data-groupIdx=$groupIdx] li:first').click();
				focusOnSelection(true);
				return true;
			}
		}

		// if( dy!=0 )
		// 	selY+=dy;
		// else if( dx!=0 )
		// 	selY+=dx*2;

		// if( selY<0 ) {
		// 	// First
		// 	jList.find("li[data-y]:first").click();
		// }
		// else if( selY>=allValues.length ) {
		// 	// Last
		// 	jList.find("li[data-y]:last").click();
		// }
		// else {
		// 	// Prev/next item
		// 	jContent.find('[data-y=$selY]').click();
		// }
		// focusOnSelection(true);
		return true;
	}


}
