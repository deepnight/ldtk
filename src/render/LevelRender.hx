package render;

class LevelRender {
	public var client(get,never) : Client; inline function get_client() return Client.ME;

	public var root : h2d.Layers;

	public var data : data.LevelData;
	var layers : Array<render.LayerRender> = [];

	public function new(d:LevelData) {
		data = d;

		root = new h2d.Layers();
		client.root.add(root, Const.DP_MAIN);

		for(d in data.layers) {
			var r = new LayerRender(d);
			root.addChild(r.root);
			layers.push(r);
		}
	}

	public function render() {
		for(l in layers)
			l.render();
	}
}
