package tool;

class TileTool extends Tool<TilesetSelection> {
	public var curTilesetDef(get,never) : Null<TilesetDef>;
	inline function get_curTilesetDef() return client.project.defs.getTilesetDef( client.curLayerInstance.def.tilesetDefId );

	public function new() {
		super();
		enablePalettePopOut();
	}

	override function getDefaultValue():TilesetSelection {
		return { rand:false, ids:[0] };
	}

	override function canEdit():Bool {
		return super.canEdit() && curTilesetDef!=null;
	}

	public function isRandomMode() return getSelectedValue().rand;

	public function setRandomMode(v:Bool) {
		getSelectedValue().rand = v;
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
		var sel = getSelectedValue();

		if( isRandomMode() ) {
			client.curLayerInstance.setGridTile(cx,cy, sel.ids[Std.random(sel.ids.length)]);
		}
		else {
			var left = Const.INFINITE;
			var top = Const.INFINITE;

			for(tid in sel.ids) {
				left = M.imin(left, curTilesetDef.getTileCx(tid));
				top = M.imin(top, curTilesetDef.getTileCy(tid));
			}

			for(tid in sel.ids)
				client.curLayerInstance.setGridTile(
					cx+curTilesetDef.getTileCx(tid)-left,
					cy+curTilesetDef.getTileCy(tid)-top,
					tid
				);
		}
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

		if( curTilesetDef==null || curTilesetDef.isEmpty() ) {
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
		var opt = new J('<label class="option"/>');
		opt.appendTo(options);
		var chk = new J('<input type="checkbox"/>');
		chk.prop("checked", isRandomMode());
		chk.change( function(ev) {
			setRandomMode( chk.prop("checked")==true );
			client.ge.emit(ToolOptionChanged);
		});
		opt.append(chk);
		opt.append('Random tiles');
		opt.append('<div class="key">R</div>');

		return target;
	}

	override function onKeyPress(keyId:Int) {
		super.onKeyPress(keyId);

		switch keyId {
			case K.R :
				setRandomMode( !isRandomMode() );
				client.ge.emit(ToolOptionChanged);
		}
	}
}
