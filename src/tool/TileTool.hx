package tool;

class TileTool extends Tool< Array<Int> > {
	public var curTilesetDef(get,never) : Null<TilesetDef>;
	inline function get_curTilesetDef() return client.project.defs.getTilesetDef( client.curLayerInstance.def.tilesetDefId );

	public function new() {
		super();
	}

	override function getDefaultValue():Array<Int> {
		return [0];
	}

	override function canEdit():Bool {
		return super.canEdit() && curTilesetDef!=null;
	}

	function isRandomMode() return Client.ME.isCtrlDown();

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
		var tileIds = getSelectedValue();

		if( isRandomMode() ) {
			client.curLayerInstance.setGridTile(cx,cy, tileIds[Std.random(tileIds.length)]);
		}
		else {
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in tileIds) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			for(tid in tileIds)
				client.curLayerInstance.setGridTile(
					cx+curTilesetDef.getTileCx(tid)-left,
					cy+curTilesetDef.getTileCy(tid)-top,
					tid
				);
		}
	}


	function removeSelectedTileAt(cx:Int, cy:Int) {
		var tileIds = getSelectedValue();

		if( isRandomMode() )
			client.curLayerInstance.removeGridTile(cx,cy);
		else {
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in tileIds) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			for(tid in tileIds)
				client.curLayerInstance.removeGridTile(
					cx+curTilesetDef.getTileCx(tid)-left,
					cy+curTilesetDef.getTileCy(tid)-top
				);
		}
	}

	override function updateCursor(m:MouseCoords) {
		super.updateCursor(m);

		if( curTilesetDef==null || curTilesetDef.isEmpty() ) {
			client.cursor.set(None);
			return;
		}

		if( isRunning() && rectangle ) {
			var r = Rect.fromMouseCoords(origin, m);
			client.cursor.set( GridRect(curLayerInstance, r.left, r.top, r.wid, r.hei) );
		}
		else if( curLayerInstance.isValid(m.cx,m.cy) ) {
			var tileIds = getSelectedValue();
			if( isRandomMode() )
				client.cursor.set( Tiles(curLayerInstance, [ tileIds[Std.random(tileIds.length)] ], m.cx, m.cy) );
			else
				client.cursor.set( Tiles(curLayerInstance, tileIds, m.cx, m.cy) );
		}
		else
			client.cursor.set(None);
	}

	override function createPalette() {
		var target = super.createPalette();
		if( curTilesetDef!=null )
			new ui.TilesetPicker(target, this);
		return target;
	}
}
