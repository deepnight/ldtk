package data;

class Level implements data.IData {
	public var project(default,null) : Project;
	public var layers : Array<LayerContent> = [];

	public var pxWid : Int = 256;
	public var pxHei : Int = 256;

	@:allow(data.Project)
	private function new(p:data.Project) {
		project = p;

		for(def in project.layerDefs)
			layers.push( new LayerContent(this, def) );
	}

	public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function clone() {
		var e = new Level(project);
		return e;
	}

	public function toJson() {
		return {
		}
	}
}
