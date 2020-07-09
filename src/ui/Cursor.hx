package ui;

class Cursor extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : led.Project; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : led.Level; inline function get_curLevel() return Client.ME.curLevel;
	// var curLayer(get,never) : LayerInstance; inline function get_curLayer() return Client.ME.curLayerInstance;

	var type : CursorType = None;

	var wrapper : h2d.Object;
	var graphics : h2d.Graphics;

	public function new() {
		super(Client.ME);
		createRootInLayers(Client.ME.root, Const.DP_UI);

		graphics = new h2d.Graphics(root);

		wrapper = new h2d.Object(root);
		wrapper.alpha = 0.4;
	}

	override function onResize() {
		super.onResize();
	}

	function render() {
		wrapper.removeChildren();
		graphics.clear();
		graphics.lineStyle(0);
		graphics.endFill();

		root.visible = type!=None && !Modal.hasAnyOpen() && client.isCurrentLayerVisible();
		hxd.System.setCursor(Default);

		var pad = 2;

		switch type {
			case None:

			case Resize(pos):
				#if js
				hxd.System.setCursor( hxd.Cursor.CustomCursor.getNativeCursor(switch pos {
					case Top: "n-resize";
					case Bottom: "s-resize";
					case Left: "w-resize";
					case Right: "e-resize";
					case TopLeft: "nw-resize";
					case TopRight: "ne-resize";
					case BottomLeft: "sw-resize";
					case BottomRight: "se-resize";
				}) );
				#end

			case Move:
				hxd.System.setCursor(Move);

			case Eraser(x, y):
				graphics.lineStyle(1, 0xff0000, 1);
				graphics.drawCircle(0,0, 6);
				graphics.lineStyle(1, 0x880000, 1);
				graphics.drawCircle(0,0, 8);

			case GridCell(li, cx, cy, col):
				if( col==null )
					col = 0x0;
				graphics.lineStyle(1, getOpposite(col), 0.8);
				graphics.drawRect(-pad, -pad, li.def.gridSize+pad*2, li.def.gridSize+pad*2);

				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, li.def.gridSize, li.def.gridSize);

			case GridRect(li, cx, cy, wid, hei, col):
				if( col==null )
					col = 0x0;
				graphics.lineStyle(1, getOpposite(col), 0.8);
				graphics.drawRect(-2, -2, li.def.gridSize*wid+4, li.def.gridSize*hei+4);

				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, li.def.gridSize*wid, li.def.gridSize*hei);

			case Entity(def, x, y):
				graphics.lineStyle(1, getOpposite(def.color), 0.8);
				graphics.drawRect(
					-pad -def.width*def.pivotX,
					-pad -def.height*def.pivotY,
					def.width + pad*2,
					def.height + pad*2
				);

				var o = display.LevelRender.createEntityRender(def, wrapper);

			case Tiles(li, tileIds, cx, cy):
				var td = project.defs.getTilesetDef( li.def.tilesetDefId );
				var left = Const.INFINITE;
				var top = Const.INFINITE;
				for(tid in tileIds) {
					left = M.imin( left, td.getTileCx(tid) );
					top = M.imin( top, td.getTileCy(tid) );
				}

				var gridDiffScale = M.imax(1, M.round( td.tileGridSize / li.def.gridSize ) );
				for(tid in tileIds) {
					var cx = td.getTileCx(tid);
					var cy = td.getTileCy(tid);
					var bmp = new h2d.Bitmap( td.getTile(tid), wrapper );
					bmp.x = (cx-left) * li.def.gridSize * gridDiffScale;
					bmp.y = (cy-top) * li.def.gridSize * gridDiffScale;
				}
		}

		graphics.endFill();
		customRender();
		updatePosition();
	}

	public dynamic function customRender() {}

	function getOpposite(c:UInt) { // black or white
		return C.interpolateInt(c, C.getPerceivedLuminosityInt(c)>=0.7 ? 0x0 : 0xffffff, 0.5);
	}

	public function set(t:CursorType) {
		var changed = type==null || !type.equals(t);
		type = t;
		if( changed )
			render();
	}

	public function updatePosition() {
		if( type==None )
			return;

		switch type {
			case None, Move:
			case Resize(_):

			case Eraser(x, y):
				wrapper.setPosition(x,y);

			case GridCell(li, cx, cy), GridRect(li, cx,cy, _):
				wrapper.setPosition( cx*li.def.gridSize, cy*li.def.gridSize );

			case Entity(def, x,y):
				wrapper.setPosition(x,y);

			case Tiles(li, tileIds, cx, cy):
				wrapper.setPosition(cx*li.def.gridSize, cy*li.def.gridSize);
		}

		graphics.setPosition(wrapper.x, wrapper.y);
	}

	public function highlight() {
		root.filter = new h2d.filter.Group([
			new h2d.filter.Glow(0x8effcb,1, 4, 2, 2, true),
			new h2d.filter.Glow(0x6296ff,0.6, 8, 1, 2, true),
		]);
	}

	override function postUpdate() {
		super.postUpdate();

		root.x = client.levelRender.root.x;
		root.y = client.levelRender.root.y;
		root.setScale(client.levelRender.zoom);

		updatePosition();
	}

	override function update() {
		super.update();
	}
}