package ui.palette;

class EntityPalette extends ui.ToolPalette {
	var allTagGroups: Array<{ tag:Null<String>, all:Array<data.def.EntityDef> }>;

	public function new(t) {
		super(t);
	}

	override function doRender() {
		super.doRender();

		var tool : tool.lt.EntityTool = cast tool;

		jList = new J('<ul class="niceList"/>');
		jList.appendTo(jContent);

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
				var jTag = new J('<li class="title"/>');
				jTag.appendTo(jList);
				jTag.text( group.tag==null ? L._Untagged() : group.tag );
			}

			var jLi = new J('<li class="subList"> <ul/> </li>');
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
				jLi.append( JsTools.createEntityPreview(Editor.ME.project, ed) );
				jLi.append(ed.identifier);

				jLi.click( function(_) {
					tool.selectValue(ed.uid);
					render();
				});
				y++;
			}

			groupIdx++;
		}
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
			jContent.find('[data-y=$selY]').click();
			focusOnSelection(true);
		}
		else if( dx!=0 ) {
			// Prev/next tag group
			if( dx<0 && !jContent.find("li.active").is('[data-groupIdx=$groupIdx] li:first') ) {
				jContent.find('[data-groupIdx=$groupIdx] li:first').click();
				focusOnSelection(true);
				return true;
			}
			else if( dx>0 && groupIdx==allTagGroups.length-1 ) {
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