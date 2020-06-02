package render;

class LevelRender extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;

	public var data : data.LevelData;
	var layers : Array<render.LayerRender> = [];
	var layerVis : Map<LayerContent,Bool> = new Map();
	var invalidated = true;

	var grid : h2d.Graphics;

	public var focusX : Float = 0.;
	public var focusY : Float = 0.;
	public var zoom : Float = 3.0;

	public function new(d:LevelData) {
		super(client);

		data = d;
		createRootInLayers(client.root, Const.DP_MAIN);

		grid = new h2d.Graphics(root);

		for(d in data.layers) {
			var r = new LayerRender(d);
			root.addChild(r.root);
			layers.push(r);
			showLayer(d);
		}
	}

	public inline function isLayerVisible(l:LayerContent) {
		return !layerVis.exists(l) || layerVis.get(l)==true;
	}

	public function toggleLayer(l:LayerContent) {
		layerVis.set(l, !isLayerVisible(l));
		invalidate();
	}

	public function showLayer(l:LayerContent) {
		layerVis.set(l, true);
		invalidate();
	}

	public function hideLayer(l:LayerContent) {
		layerVis.set(l, false);
		invalidate();
	}

	public function renderGrid() {
		var l = client.curLayer;
		grid.clear();
		grid.lineStyle(1, 0x0, 0.2);
		for( cx in 0...client.curLayer.cWid+1 ) {
			grid.moveTo(cx*l.def.gridSize, 0);
			grid.lineTo(cx*l.def.gridSize, l.cHei*l.def.gridSize);
		}
		for( cy in 0...client.curLayer.cHei+1 ) {
			grid.moveTo(0, cy*l.def.gridSize);
			grid.lineTo(l.cWid*l.def.gridSize, cy*l.def.gridSize);
		}
	}

	public function render() {
		for(lr in layers)
			if( isLayerVisible(lr.data) )
				lr.render();

		updateLayersVisibility();
		renderGrid();
	}

	function updateLayersVisibility() {
		for(lr in layers) {
			lr.root.visible = isLayerVisible(lr.data);
			lr.root.alpha = lr.data==client.curLayer ? 1 : 0.4;
		}
	}

	public function onCurrentLayerChange(cur:LayerContent) {
		updateLayersVisibility();
		renderGrid();
	}


	public inline function invalidate() {
		invalidated = true;
	}

	override function postUpdate() {
		super.postUpdate();

		root.setScale(zoom);
		root.x = w()*0.5 - focusX * zoom;
		root.y = h()*0.5 - focusY * zoom;

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}

}
