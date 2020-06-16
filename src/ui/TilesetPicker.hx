package ui;

class TilesetPicker {
	var jDoc(get,never) : js.jquery.JQuery; inline function get_jDoc() return new J(js.Browser.document);
	var wrapper : js.jquery.JQuery;

	var tool : tool.TileTool;
	var zoom = 2.0;
	var curSelection : Array<js.jquery.JQuery> = [];
	var cursor : js.jquery.JQuery;

	var dragStart : Null<{ x:Int, y:Int }>;

	public function new(target:js.jquery.JQuery, tool:tool.TileTool) {
		this.tool = tool;

		// Create picker elements
		wrapper = new J("<div/>");
		wrapper.appendTo(target);
		wrapper.css("zoom",zoom);

		cursor = new J('<div class="tileCursor"/>');
		cursor.prependTo(wrapper);

		var img = new J( tool.curTilesetDef.createAtlasHtmlImage() );
		img.appendTo(wrapper);

		// Init events
		img.mousedown( function(ev) {
			N.debug("down");
			ev.preventDefault();
			onPickerMouseDown(ev);
			jDoc
				.off(".pickerEvent")
				.on("mouseup.pickerEvent", onDocMouseUp)
				.on("mousemove.pickerEvent", onDocMouseMove);
		});

		img.mousemove( onPickerMouseMove );

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
				for(tileId in tiles)
					createSelectionCursor(tileId);
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

	function updateCursor(pageX:Float, pageY:Float) {
		var grid = tool.curTilesetDef.tileGridSize;
		var r = getCursorRect(pageX, pageY);
		cursor.css("margin-left", r.cx*grid + "px");
		cursor.css("margin-top", r.cy*grid + "px");
		cursor.css("width", r.wid*grid + "px");
		cursor.css("height", r.hei*grid + "px");
	}

	function onDocMouseMove(ev:js.jquery.Event) {
		updateCursor(ev.pageX, ev.pageY);
	}

	function onDocMouseUp(ev:js.jquery.Event) {
		jDoc.off(".pickerEvent");

		if( dragStart!=null ) {
			var r = getCursorRect(ev.pageX, ev.pageY);

			// Apply selection
			if( r.wid==1 && r.hei==1 )
				tool.selectValue( Single( tool.curTilesetDef.coordId(r.cx,r.cy) ) );
			else {
				var tileIds = [];
				for(cx in r.cx...r.cx+r.wid)
				for(cy in r.cy...r.cy+r.hei)
					tileIds.push( tool.curTilesetDef.coordId(cx,cy) );
				tool.selectValue( Multiple(tileIds) );
			}
		}

		dragStart = null;
	}


	function onPickerMouseDown(ev:js.jquery.Event) {
		dragStart = {
			x: Std.int( ev.offsetX / zoom ),
			y: Std.int( ev.offsetY / zoom ),
		}
	}

	function onPickerMouseMove(ev:js.jquery.Event) {
		if( dragStart==null )
			updateCursor(ev.pageX, ev.pageY);
	}

	function getCursorRect(pageX:Float, pageY:Float) {
		var curX = pageX - wrapper.offset().left * zoom;
		var curY = pageY - wrapper.offset().top * zoom;

		var grid = tool.curTilesetDef.tileGridSize;
		var curCx = Std.int( curX / grid / zoom );
		var curCy = Std.int( curY / grid / zoom );

		if( dragStart==null )
			return {
				cx: curCx,
				cy: curCy,
				wid: 1,
				hei: 1,
			}
		else {
			var startCx = Std.int(dragStart.x/grid);
			var startCy = Std.int(dragStart.y/grid);
			return {
				cx: M.imin(curCx,startCx),
				cy: M.imin(curCy,startCy),
				wid: M.iabs(curCx-startCx) + 1,
				hei: M.iabs(curCy-startCy) + 1,
			}
		}
	}
}