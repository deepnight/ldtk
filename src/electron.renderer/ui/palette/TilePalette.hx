package ui.palette;

class TilePalette extends ui.ToolPalette {
	public var picker : Null<TilesetPicker>;

	public function new(t) {
		super(t);
		canPopOut = true;
	}

	override function doRender() {
		super.doRender();

		var tool : tool.lt.TileTool = cast tool;

		if( tool.curTilesetDef==null ) {
			jContent.addClass("invalid");
			jContent.append('<div class="warning">'+Lang.t._("This tile layer has no Tileset.")+'</div>');
			return;
		}

		jContent.removeClass("invalid");

		// Picker
		picker = new ui.TilesetPicker(jContent, tool.curTilesetDef, ToolPicker, tool);

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

	override function focusOnSelection() {
		super.focusOnSelection();
		if( picker!=null )
			picker.focusOnSelection();
	}

	override function update() {
		super.update();

		if( picker!=null )
			picker.update();
	}
}