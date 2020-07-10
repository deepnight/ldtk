package tool;

class TileTool extends Tool<led.LedTypes.TilesetSelection> {
	public var curTilesetDef(get,never) : Null<led.def.TilesetDef>;
	inline function get_curTilesetDef() return client.project.defs.getTilesetDef( client.curLayerInstance.def.tilesetDefId );

	public function new() {
		super();
		enablePalettePopOut();
		selectValue( getSelectedValue() );
	}

	override function getDefaultValue():led.LedTypes.TilesetSelection {
		return { mode:Stamp, ids:[0] };
	}

	override function canEdit():Bool {
		return super.canEdit() && curTilesetDef!=null;
	}


	public function getMode() return getSelectedValue().mode;

	public function setMode(m:led.LedTypes.TileEditMode) {
		getSelectedValue().mode = m;
	}

	public function isRandomMode() return getSelectedValue().mode==Random;

	override function useAt(m:MouseCoords) {
		super.useAt(m);

		var anyChange = false;
		switch curMode {
			case null, PanView:

			case Add:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					if( drawSelectionAt(cx, cy) )
						anyChange = true;
				});

			case Remove:
				dn.Bresenham.iterateThinLine(lastMouse.cx, lastMouse.cy, m.cx, m.cy, function(cx,cy) {
					if( removeSelectedTileAt(cx, cy) )
						anyChange = true;
				});

			case Move:
		}

		return anyChange;
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		if( curMode==Add && !isRandomMode() )
			return drawSelectionInRectangle(left,top, right-left+1, bottom-top+1);

		var anyChange = false;
		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null, PanView:
				case Add:
					if( drawSelectionAt(cx,cy) ) // random mode only
						anyChange = true;

				case Remove:
					if( client.curLayerInstance.hasGridTile(cx,cy) ) {
						client.curLayerInstance.removeGridTile(cx,cy);
						anyChange = true;
					}

				case Move:
			}
		}

		return anyChange;
	}


	function drawSelectionInRectangle(cx:Int, cy:Int, wid:Int, hei:Int) {
		var anyChange = false;
		var sel = getSelectedValue();
		var selMap = new Map();

		var selLeft = Const.INFINITE;
		var selTop = Const.INFINITE;
		var selRight = -Const.INFINITE;
		var selBottom = -Const.INFINITE;

		for(tid in sel.ids) {
			selMap.set(tid,true);
			selLeft = M.imin(selLeft, curTilesetDef.getTileCx(tid));
			selRight = M.imax(selRight, curTilesetDef.getTileCx(tid));
			selTop = M.imin(selTop, curTilesetDef.getTileCy(tid));
			selBottom = M.imax(selBottom, curTilesetDef.getTileCy(tid));
		}

		var selWid = selRight-selLeft+1;
		var selHei = selBottom-selTop+1;
		var curX = cx;
		var curY = cy;
		for( x in cx...cx+wid )
		for( y in cy...cy+hei ) {
			var tcx = selLeft + (x-cx)%selWid;
			var tcy = selTop + (y-cy)%selHei;
			var tid = curTilesetDef.getTileId(tcx,tcy);
			if( curLayerInstance.getGridTile(x,y)!=tid && selMap.exists(tid) ) {
				curLayerInstance.setGridTile(x,y, tid);
				anyChange = true;
			}
		}

		return anyChange;
	}

	function drawSelectionAt(cx:Int, cy:Int) {
		var anyChange = false;
		var sel = getSelectedValue();

		if( isRandomMode() ) {
			// Single random tile
			var tid = sel.ids[Std.random(sel.ids.length)];
			if( tid!=curLayerInstance.getGridTile(cx,cy) ) {
				curLayerInstance.setGridTile(cx,cy, tid);
				anyChange = true;
			}
		}
		else {
			// Stamp
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			var gridDiffScale = M.imax(1, M.round( curTilesetDef.tileGridSize / curLayerInstance.def.gridSize ) );
			for(tid in sel.ids) {
				var tcx = cx + ( curTilesetDef.getTileCx(tid) - left ) * gridDiffScale;
				var tcy = cy + ( curTilesetDef.getTileCy(tid) - top ) * gridDiffScale;
				if( curLayerInstance.getGridTile(tcx,tcy)!=tid ) {
					curLayerInstance.setGridTile(tcx,tcy,tid);
					anyChange = true;
				}
			}
		}
		return anyChange;
	}


	function removeSelectedTileAt(cx:Int, cy:Int) {
		var sel = getSelectedValue();

		var anyChange = false;
		if( isRandomMode() ) {
			if( client.curLayerInstance.hasGridTile(cx,cy) ) {
				client.curLayerInstance.removeGridTile(cx,cy);
				anyChange = true;
			}
		}
		else {
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			for(tid in sel.ids) {
				var tcx = cx+curTilesetDef.getTileCx(tid)-left;
				var tcy = cy+curTilesetDef.getTileCy(tid)-top;
				if( client.curLayerInstance.hasGridTile(tcx,tcy) ) {
					client.curLayerInstance.removeGridTile(tcx,tcy);
					anyChange = true;
				}
			}
		}

		return anyChange;
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( curTilesetDef==null || !curTilesetDef.hasAtlas() ) {
			client.cursor.set(None);
			return;
		}

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			client.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) ) {
			var sel = getSelectedValue();
			if( isRandomMode() )
				client.cursor.set( Tiles(curLayerInstance, [ sel.ids[Std.random(sel.ids.length)] ], m.cx, m.cy) );
			else
				client.cursor.set( Tiles(curLayerInstance, sel.ids, m.cx, m.cy) );
		}
		else
			client.cursor.set(None);
	}

	override function createPalette() {
		var target = super.createPalette();

		if( curTilesetDef!=null )
			new ui.TilesetPicker(target, this);


		var options = new J('<div class="toolOptions"/>');
		options.appendTo(target);

		// Save selection
		var bt = new J('<button/>');
		bt.appendTo(options);
		bt.append( JsTools.createKeyInLabel("[S]ave selection") );
		bt.click( function(_) {
			saveSelection();
		});

		// Random mode
		var opt = new J('<label/>');
		opt.appendTo(options);
		var chk = new J('<input type="checkbox"/>');
		chk.prop("checked", isRandomMode());
		chk.change( function(ev) {
			setMode( chk.prop("checked")==true ? Random : Stamp );
			client.ge.emit(ToolOptionChanged);
		});
		opt.append(chk);
		opt.append( JsTools.createKeyInLabel("[R]andom mode") );

		return target;
	}

	function saveSelection() {
		curTilesetDef.saveSelection( getSelectedValue() );
		client.ge.emit(TilesetDefChanged);
		N.msg("Saved selection");
	}

	override function onKeyPress(keyId:Int) {
		super.onKeyPress(keyId);

		if( !client.hasAnyToggleKeyDown() )
			switch keyId {
				case K.R :
					setMode( isRandomMode() ? Stamp : Random );
					client.ge.emit(ToolOptionChanged);

				case K.S:
					saveSelection();
			}
	}
}
