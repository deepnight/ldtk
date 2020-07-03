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
					removeSelectedTileAt(cx, cy); // TODO anychange update
				});

			case Move:
		}

		return anyChange;
	}

	override function useOnRectangle(left:Int, right:Int, top:Int, bottom:Int) {
		super.useOnRectangle(left, right, top, bottom);

		var anyChange = false;
		for(cx in left...right+1)
		for(cy in top...bottom+1) {
			switch curMode {
				case null, PanView:
				case Add:
					if( drawSelectionAt(cx,cy) )
						anyChange = true;

				case Remove:
					removeSelectedTileAt(cx,cy); // TODO anychange

				case Move:
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

		if( isRandomMode() )
			client.curLayerInstance.removeGridTile(cx,cy);
		else {
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			for(tid in sel.ids)
				client.curLayerInstance.removeGridTile(
					cx+curTilesetDef.getTileCx(tid)-left,
					cy+curTilesetDef.getTileCy(tid)-top
				);
		}
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
		bt.append( JsTools.keyInLabel("[S]ave selection") );
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
		opt.append( JsTools.keyInLabel("[R]andom mode") );

		return target;
	}

	function saveSelection() {
		curTilesetDef.saveSelection( getSelectedValue() );
		client.ge.emit(TilesetDefChanged);
		N.msg("Saved selection");
	}

	override function onKeyPress(keyId:Int) {
		super.onKeyPress(keyId);

		switch keyId {
			case K.R :
				setMode( isRandomMode() ? Stamp : Random );
				client.ge.emit(ToolOptionChanged);

			case K.S:
				saveSelection();
		}
	}
}
