package ui.palette;

class EntityPalette extends ui.ToolPalette {
	var scrollY = 0.;

	public function new(t) {
		super(t);
	}

	override function render() {
		super.render();
		var tool : tool.EntityTool = cast tool;

		var list = new J('<ul class="niceList"/>');
		list.appendTo(jContent);

		for(ed in Editor.ME.project.defs.entities) {
			var e = new J("<li/>");
			list.append(e);
			e.addClass("entity");
			if( ed==tool.curEntityDef ) {
				e.addClass("active");
				e.css( "background-color", C.intToHex( C.toWhite(ed.color, 0.7) ) );
			}
			else
				e.css( "color", C.intToHex( C.toWhite(ed.color, 0.5) ) );

			e.append( JsTools.createEntityPreview(Editor.ME.project, ed) );
			e.append(ed.identifier);

			e.click( function(_) {
				tool.selectValue(ed.uid);
				render();
			});
		}

		// Scrolling memory
		list.scroll(function(ev) {
			scrollY = list.scrollTop();
		});
		list.scrollTop(scrollY);

	}
}