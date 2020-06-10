package data;

class LevelData implements data.ISerializable {
	var _project : ProjectData;

	public var uid(default,null) : Int;
	public var pxWid : Int = 512;
	public var pxHei : Int = 256;
	public var layerInstances : Map<Int,LayerInstance> = new Map();


	@:allow(data.ProjectData)
	private function new(project:ProjectData, uid:Int) {
		this.uid = uid;
		this._project = project;

		for(ld in _project.defs.layers)
			layerInstances.set( ld.uid, new LayerInstance(_project, uid, ld.uid) );
	}

	@:keep public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function clone() {
		return fromJson( _project, toJson() );
	}

	public function toJson() {
		var layersJson = [];
		for(li in layerInstances)
			layersJson.push( li.toJson() );

		return {
			uid: uid,
			pxWid: pxWid,
			pxHei: pxHei,
			layerInstances : layersJson,
		}
	}

	public static function fromJson(project:ProjectData, json:Dynamic) {
		var l = new LevelData( project, JsonTools.readInt(json.uid) );
		return l;
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

		// Create missing layerInstances
		for(ld in project.defs.layers)
			if( !layerInstances.exists(ld.uid) )
				layerInstances.set( ld.uid, new LayerInstance(project, uid, ld.uid) );

		// Layer instances content
		for(li in layerInstances)
			li.tidy(project);

	}

}
