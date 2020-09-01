package ui.palette;

class TilePalette extends ui.ToolPalette {
	var scrollX = 0.;
	var scrollY = 0.;

	public function new(t) {
		super(t);
	}

	override function render() {
		super.render();

		var tool : tool.TileTool = cast tool;

		if( tool.curTilesetDef==null ) {
			jContent.addClass("invalid");
			jContent.append('<div class="warning">'+Lang.t._("This tile layer has no Tileset.")+'</div>');
			return;
		}

		jContent.removeClass("invalid");

		// Picker
		new ui.TilesetPicker(jContent, tool.curTilesetDef, tool);

		var options = new J('<div class="toolOptions"/>');
		options.appendTo(jContent);

		// Save selection
		var bt = new J('<button/>');
		bt.appendTo(options);
		bt.append( JsTools.createKeyInLabel("[S]ave selection") );
		bt.click( function(_) {
			tool.saveSelection();
		});

		// Random mode
		N.debug("rand="+tool.isRandomMode());
		var opt = new J('<label/>');
		opt.appendTo(options);
		var chk = new J('<input type="checkbox"/>');
		chk.prop("checked", tool.isRandomMode());
		chk.change( function(ev) {
			tool.setMode( chk.prop("checked")==true ? Random : Stamp );
			Editor.ME.ge.emit(ToolOptionChanged);
			render();
		});
		opt.append(chk);
		opt.append( JsTools.createKeyInLabel("[R]andom mode") );
	}
}