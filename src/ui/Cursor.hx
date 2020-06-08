package ui;

class Cursor extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	// var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayerContent;

	var type : CursorType = None;

	var wrapper : h2d.Object;
	var graphics : h2d.Graphics;

	public function new() {
		super(Client.ME);
		createRootInLayers(Client.ME.root, Const.DP_UI);
		graphics = new h2d.Graphics(root);
		wrapper = new h2d.Object(root);
	}

	override function onResize() {
		super.onResize();
	}

	function render() {
		wrapper.removeChildren();
		graphics.clear();
		graphics.lineStyle(0);
		graphics.endFill();

		root.visible = type!=None && !Modal.hasAnyOpen();
		hxd.System.setCursor(Default);

		var pad = 2;

		switch type {
			case None:

			case Move:
				hxd.System.setCursor(Move);

			case Eraser(x, y):
				graphics.lineStyle(1, 0xff0000, 1);
				graphics.drawCircle(0,0, 6);
				graphics.lineStyle(1, 0x880000, 1);
				graphics.drawCircle(0,0, 8);

			case GridCell(lc, cx, cy, col):
				if( col==null )
					col = 0x0;
				graphics.lineStyle(1, getOpposite(col), 0.8);
				graphics.drawRect(-pad, -pad, lc.def.gridSize+pad*2, lc.def.gridSize+pad*2);

				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, lc.def.gridSize, lc.def.gridSize);

			case GridRect(lc, cx, cy, wid, hei, col):
				if( col==null )
					col = 0x0;
				graphics.lineStyle(1, getOpposite(col), 0.8);
				graphics.drawRect(-2, -2, lc.def.gridSize*wid+4, lc.def.gridSize*hei+4);

				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, lc.def.gridSize*wid, lc.def.gridSize*hei);

			case Entity(def, x, y):
				graphics.lineStyle(1, getOpposite(def.color), 0.8);
				graphics.drawRect(
					-pad -def.width*def.pivotX,
					-pad -def.height*def.pivotY,
					def.width + pad*2,
					def.height + pad*2
				);

				var o = EntityInstance.createRender(def, wrapper);
				o.alpha = 0.4;
		}

		graphics.endFill();
		updatePosition();
	}

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

			case Eraser(x, y):
				wrapper.setPosition(x,y);

			case GridCell(lc, cx, cy), GridRect(lc, cx,cy, _):
				wrapper.setPosition( cx*lc.def.gridSize, cy*lc.def.gridSize );

			case Entity(def, x,y):
				wrapper.setPosition(x,y);
		}

		graphics.setPosition(wrapper.x, wrapper.y);
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