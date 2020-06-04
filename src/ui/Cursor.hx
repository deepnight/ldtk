package ui;

class Cursor extends dn.Process {
	var client(get,never) : Client; inline function get_client() return Client.ME;
	var project(get,never) : ProjectData; inline function get_project() return Client.ME.project;
	var curLevel(get,never) : LevelData; inline function get_curLevel() return Client.ME.curLevel;
	var curLayer(get,never) : LayerContent; inline function get_curLayer() return Client.ME.curLayerContent;

	var type : CursorType = None;

	var renderWrapper : h2d.Object;
	var graphics : h2d.Graphics;

	public function new() {
		super(Client.ME);
		createRootInLayers(Client.ME.root, Const.DP_UI);
		renderWrapper = new h2d.Object(root);
		graphics = new h2d.Graphics(renderWrapper);
	}

	override function onResize() {
		super.onResize();
	}

	function render() {
		graphics.clear();
		root.visible = type!=None;

		switch type {
			case None:

			case GridCell(cx, cy, col):
				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, curLayer.def.gridSize, curLayer.def.gridSize);

			case GridRect(cx, cy, wid, hei, col):
				graphics.lineStyle(1, col==null ? 0x0 : col);
				graphics.drawRect(0, 0, curLayer.def.gridSize*wid, curLayer.def.gridSize*hei);
		}

		graphics.endFill();
		updatePosition();
	}

	public function set(t:CursorType) {
		var changed = type==null || !type.equals(t);
		type = t;
		if( changed )
			render();
	}

	function updatePosition() {
		if( type==None )
			return;

		switch type {
			case None:

			case GridCell(cx, cy), GridRect(cx,cy, _):
				renderWrapper.setPosition( cx*curLayer.def.gridSize, cy*curLayer.def.gridSize );
		}
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