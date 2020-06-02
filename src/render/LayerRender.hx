package render;

class LayerRender {
	public var root : h2d.Object;
	public var data : LayerContent;

	var gridSize(get,never) : Int; inline function get_gridSize() return data.def.gridSize;

	public function new(d:data.LayerContent) {
		data = d;
		root = new h2d.Object();
	}

	public function render() {
		root.removeChildren();

		switch data.def.type {
			case IntGrid:
				var g = new h2d.Graphics(root);
				for(cy in 0...data.cHei)
				for(cx in 0...data.cWid) {
					var id = data.getIntGrid(cx,cy);
					if( id<0 )
						continue;

					g.beginFill(data.def.intGridValues[id].color);
					g.drawRect(cx*gridSize, cy*gridSize, gridSize, gridSize);
				}

			case Entities:
				// TODO
		}
	}
}
