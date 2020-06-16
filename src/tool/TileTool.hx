package tool;

class TileTool extends Tool<TileSelection> {
	var randomMode = false;
	var curTilesetDef(get,never) : TilesetDef; inline function get_curTilesetDef() return client.curLayerInstance.def.tilesetDef;

	public function new() {
		super();
	}

	// override function selectValue(v:Int) {
	// 	super.selectValue(v);
	// }

	// override function canEdit():Bool {
	// 	return super.canEdit() && getSelectedValue()>=0;
	// }

	override function getDefaultValue():TileSelection{
		// return Multiple([
		// 	{ tcx:0, tcy:0 },
		// 	{ tcx:1, tcy:0 },
		// 	{ tcx:2, tcy:0 },
		// ]);
		return Single(0);
	}

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		switch curMode {
			case null, PanView:
			case Add:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					drawSelectionAt(cx, cy);
				});
				client.ge.emit(LayerInstanceChanged);

			case Remove:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					removeSelectedTileAt(cx, cy);
				});
				client.ge.emit(LayerInstanceChanged);

			case Move:
		}
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null, PanView:
				case Add:
					drawSelectionAt(cx,cy);

				case Remove:
					removeSelectedTileAt(cx,cy);

				case Move:
			}
		}

		client.ge.emit(LayerInstanceChanged);
	}


	function drawSelectionAt(cx:Int, cy:Int) {
		switch getSelectedValue() {
			case Single(tileId):
				client.curLayerInstance.setGridTile(cx,cy, tileId);

			case Multiple(tiles):
				if( randomMode ) {
					// TODO
				}
				else {
					var left = Const.INFINITE;
					var top = Const.INFINITE;
					for(t in tiles) {
						left = M.imin(t.tcx, left);
						top = M.imin(t.tcy, top);
					}
					for(t in tiles)
						client.curLayerInstance.setGridTile(cx+t.tcx-left, cy+t.tcy-top, 0); // TODO
				}
		}
	}

	function removeSelectedTileAt(cx:Int, cy:Int) {
		switch getSelectedValue() {
			case Single(tileId):
				client.curLayerInstance.removeGridTile(cx,cy);

			case Multiple(tiles):
				var left = Const.INFINITE;
				var top = Const.INFINITE;
				for(t in tiles) {
					left = M.imin(t.tcx, left);
					top = M.imin(t.tcy, top);
				}
				for(t in tiles)
					client.curLayerInstance.removeGridTile(cx+t.tcx-left, cy+t.tcy-top);
		}
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			client.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) )
			client.cursor.set( GridCell(curLayerInstance, m.cx, m.cy) );
		else
			client.cursor.set(None);
	}

	override function createPalette() {
		var target = super.createPalette();

		var picker = new ui.TilesetPicker(target, curTilesetDef, selectValue);

		// var cursor = new J('<div class="tileCursor"/>');
		// cursor.prependTo( jPalette );

		// var img = new J( curTilesetDef.createAtlasHtmlImage() );
		// img.appendTo(jPalette);


		// function onMouseDown(ev:js.jquery.Event) {
		// 	var cx = Std.int( ev.offsetX / curTilesetDef.tileGridSize );
		// 	var cy = Std.int( ev.offsetY / curTilesetDef.tileGridSize );
		// 	if( ev.button==0 ) {
		// 		selectValue( Single(curTilesetDef.coordId(cx,cy)) );
		// 		N.debug( getSelectedValue() );
		// 	}
		// }

		// function onMouseUp(ev:js.jquery.Event) {
		// }

		// function onMouseMove(ev:js.jquery.Event) {
		// 	var cx = Std.int( ev.offsetX / curTilesetDef.tileGridSize );
		// 	var cy = Std.int( ev.offsetY / curTilesetDef.tileGridSize );

		// 	cursor.css("margin-left", (cx*curTilesetDef.tileGridSize)+"px");
		// 	cursor.css("margin-top", (cy*curTilesetDef.tileGridSize)+"px");
		// 	cursor.css("width", curTilesetDef.tileGridSize+"px");
		// 	cursor.css("height", curTilesetDef.tileGridSize+"px");
		// }

		// img.mousedown( function(ev) {
		// 	ev.preventDefault();
		// 	onMouseDown(ev);
		// });

		// img.mouseup( function(ev) {
		// 	onMouseUp(ev);
		// });

		// img.mousemove( function(ev) {
		// 	onMouseMove(ev);
		// });

		// var doc = new J(js.Browser.document);
		// doc.on("mouseup", function(ev) {
		// 	onMouseUp(ev);
		// });

		return target;
	}
}
