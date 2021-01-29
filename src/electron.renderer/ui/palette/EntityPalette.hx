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

		for(ed in Editor.ME.project.defs.entities) {
			var e = new J("<li/>");
			jList.append(e);
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