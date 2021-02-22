package ui.palette;

class EntityPalette extends ui.ToolPalette {
	public function new(t) {
		super(t);
	}

	override function doRender() {
		super.doRender();

		var tool : tool.lt.EntityTool = cast tool;

		jList = new J('<ul class="niceList"/>');
		jList.appendTo(jContent);

		var ld = Editor.ME.curLayerDef;

		var allTags = Editor.ME.project.defs.getEntityTagCategories();
		for(t in allTags) {
			// Tag header
			var jTag = new J('<li class="title"/>');
			jTag.appendTo(jList);
			jTag.text( t==null ? L.t._("Untagged") : t );
			var jLi = new J('<li class="subList"> <ul/> </li>');
			jLi.appendTo(jList);
			var jSubList = jLi.find("ul");

			var count = 0;
			for(ed in Editor.ME.project.defs.entities) {
				if( ed.tags.hasTagFoundIn(ld.excludedTags) || t==null && !ed.tags.isEmpty() || t!=null && !ed.tags.has(t) )
					continue;

				if( !ld.requiredTags.isEmpty() && !ed.tags.hasTagFoundIn(ld.requiredTags) )
					continue;

				var e = new J("<li/>");
				e.appendTo(jSubList);
				e.attr("data-defUid", ed.uid);
				e.addClass("entity");
				e.css( "border-color", C.intToHex(ed.color) );

				// State
				if( ed==tool.curEntityDef ) {
					e.addClass("active");
					e.css( "background-color", makeBgActiveColor(ed.color) );
				}
				else {
					e.css( "background-color", makeBgInactiveColor(ed.color) );
					e.css( "color", makeTextInactiveColor(ed.color) );
				}

				// Preview and label
				e.append( JsTools.createEntityPreview(Editor.ME.project, ed) );
				e.append(ed.identifier);

				e.click( function(_) {
					tool.selectValue(ed.uid);
					render();
				});

				count++;
			}

			// Empty tag
			if( count==0 )
				jTag.hide();
		}

	}

	override function focusOnSelection() {
		super.focusOnSelection();

		// Focus scroll animation
		var e = jList.find('[data-defUid=${tool.getSelectedValue()}]');
		if( e.length>0 )
			animateListScrolling(e.position().top + e.outerHeight()*0.5 );
	}
}