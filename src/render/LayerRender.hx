package render;

class LayerRender {
	public var root : h2d.Object;
	var data : LayerContent;

	var gridSize(get,never) : Int; inline function get_gridSize() return data.def.gridSize;

	public function new(d:data.LayerContent) {
		data = d;
		root = new h2d.Object();
	}

	public function render() {
		root.removeChildren();

		var g = new h2d.Graphics(root);
		for(cy in 0...data.cHei)
		for(cx in 0...data.cWid) {
			if( data.getIntGrid(cx,cy)<0 )
				continue;
			g.beginFill(0xff0000);
			g.drawRect(cx*gridSize, cy*gridSize, gridSize, gridSize);
		}
	}
}
