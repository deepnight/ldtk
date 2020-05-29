package render;

class LevelRender {
	public var data : data.Level;
	var layers : Array<render.LayerRender> = [];

	public function new(d:Level) {
		data = d;
		for(d in data.layers)
			layers.push( new LayerRender(d) );
	}

	public function render() {
		for(l in layers)
			l.render();
	}
}
