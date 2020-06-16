package ui;

class TilesetPicker {
	var wrapper : js.jquery.JQuery;
	var tool : tool.TileTool;
	var zoom = 2.0;
	var curSelection : Array<js.jquery.JQuery> = [];
	var cursor : js.jquery.JQuery;

	public function new(target:js.jquery.JQuery, tool:tool.TileTool) {
		this.tool = tool;

		wrapper = new J("<div/>");
		wrapper.appendTo(target);
		wrapper.css("zoom",zoom);

		cursor = new J('<div class="tileCursor"/>');
		cursor.prependTo(wrapper);

		// Init events
		var img = new J( tool.curTilesetDef.createAtlasHtmlImage() );
		img.appendTo(wrapper);

		img.mousedown( function(ev) {
			ev.preventDefault();
			onMouseDown(ev);
		});

		img.mouseup( function(ev) {
			onMouseUp(ev);
		});

		img.mousemove( function(ev) {
			onMouseMove(ev);
		});

		var doc = new J(js.Browser.document);
		doc.on("mouseup", function(ev) { // HACK need to be removed!
			onMouseUp(ev);
		});

		renderSelection();
	}

	function renderSelection() {
		for(e in curSelection)
			e.remove();
		curSelection = [];

		switch tool.getSelectedValue() {
			case Single(tileId):
				createSelectionCursor(tileId);


				case Multiple(tiles):
		}
	}


	function createSelectionCursor(tileId:Int) {
		var x = tool.curTilesetDef.getTileSourceX(tileId);
		var y = tool.curTilesetDef.getTileSourceY(tileId);

		var e = new J('<div class="tileCursor selection"/>');
		e.prependTo(wrapper);

		e.css("margin-left", x+"px");
		e.css("margin-top", y+"px");
		e.css("width", tool.curTilesetDef.tileGridSize+"px");
		e.css("height", tool.curTilesetDef.tileGridSize+"px");
	}


	function onMouseDown(ev:js.jquery.Event) {
		var cx = Std.int( ev.offsetX / tool.curTilesetDef.tileGridSize / zoom );
		var cy = Std.int( ev.offsetY / tool.curTilesetDef.tileGridSize / zoom );
		if( ev.button==0 )
			tool.selectValue( Single(tool.curTilesetDef.coordId(cx,cy)) );
	}

	function onMouseUp(ev:js.jquery.Event) {}

	function onMouseMove(ev:js.jquery.Event) {
		var grid = tool.curTilesetDef.tileGridSize;
		var cx = Std.int( ev.offsetX / grid / zoom );
		var cy = Std.int( ev.offsetY / grid / zoom );

		cursor.css("margin-left", (cx*grid)+"px");
		cursor.css("margin-top", (cy*grid)+"px");
		cursor.css("width", grid+"px");
		cursor.css("height", grid+"px");
	}
}