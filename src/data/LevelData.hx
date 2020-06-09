package data;

class LevelData implements data.IData {
	var layerInstances : Map<Int,LayerInstance> = new Map();

	public var uid(default,null) : Int;
	public var pxWid : Int = 512;
	public var pxHei : Int = 256;


	@:allow(data.ProjectData)
	private function new(uid:Int) {
		this.uid = uid;
	}

	@:keep public function toString() {
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

	public function getLayerInstance(layerDef:LayerDef) : LayerInstance {
		if( !layerInstances.exists(layerDef.uid) )
			throw "Missing layer instance for "+layerDef.name;
		return layerInstances.get( layerDef.uid );
	}

	public function tidy(project:ProjectData) {
		// Remove layerInstances without layerDefs
		for(e in layerInstances.keyValueIterator())
			if( e.value.def==null )
				layerInstances.remove(e.key);

		// Add missing layerInstances
		for(ld in project.layerDefs)
			if( !layerInstances.exists(ld.uid) )
				layerInstances.set( ld.uid, new LayerInstance(this, ld) );

		// Layer instances content
		for(li in layerInstances)
			li.tidy(project);
	}
}
