package data;

class LevelData implements data.IData {
	public var layerContents : Array<LayerContent> = [];

	public var uid : Int;
	public var pxWid : Int = 512;
	public var pxHei : Int = 256;


	@:allow(data.ProjectData)
	private function new(uid:Int) {
		this.uid = uid;
	}

	@:allow(data.ProjectData)
	function initLayersUsingProject(p:ProjectData) {
		layerContents = [];
		for(def in p.layerDefs)
			layerContents.push( new LayerContent(this, def) );
	}

	public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function clone() {
		var e = new LevelData(uid);
		return e;
	}

	public function toJson() {
		return {
		}
	}

	public function getLayerContent(layerDefId:Int) : Null<LayerContent> {
		for(lc in layerContents)
			if( lc.layerDefId==layerDefId )
				return lc;
		return null;
	}
}
