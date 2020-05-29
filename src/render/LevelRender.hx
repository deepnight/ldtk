package render;

class LevelRender extends dn.Process {
	public var client(get,never) : Client; inline function get_client() return Client.ME;

	public var data : data.LevelData;
	var layers : Array<render.LayerRender> = [];
	var layerVis : Map<LayerContent,Bool> = new Map();
	var invalidated = true;

	public function new(d:LevelData) {
		super(client);

		data = d;
		createRootInLayers(client.root, Const.DP_MAIN);

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

	public function render() {
		for(l in layers) {
			l.root.visible = isLayerVisible(l.data);
			if( isLayerVisible(l.data) )
				l.render();
		}
	}


	public inline function invalidate() {
		invalidated = true;
	}

	override function postUpdate() {
		super.postUpdate();

		if( invalidated ) {
			invalidated = false;
			render();
		}
	}

}
