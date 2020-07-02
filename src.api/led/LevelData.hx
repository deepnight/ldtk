package led;

class LevelData implements led.ISerializable {
	var _project : ProjectData;

	public var uid(default,null) : Int;
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Map<Int,LayerInstance> = new Map();


	@:allow(led.ProjectData)
	private function new(project:ProjectData, uid:Int) {
		this.uid = uid;
		pxWid = Const.DEFAULT_LEVEL_WIDTH;
		pxHei = Const.DEFAULT_LEVEL_HEIGHT;
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

	public static function fromJson(p:ProjectData, json:Dynamic) {
		var l = new LevelData( p, JsonTools.readInt(json.uid) );
		l.pxWid = JsonTools.readInt( json.pxWid, Const.DEFAULT_LEVEL_WIDTH );
		l.pxHei = JsonTools.readInt( json.pxHei, Const.DEFAULT_LEVEL_HEIGHT );

		for( layerJson in JsonTools.readArray(json.layerInstances) ) {
			var li = LayerInstance.fromJson(p, layerJson);
			l.layerInstances.set(li.layerDefId, li);
		}

		return l;
	}

	public function getLayerInstance(layerDef:led.def.LayerDef) : LayerInstance {
		if( !layerInstances.exists(layerDef.uid) )
			throw "Missing layer instance for "+layerDef.name;
		return layerInstances.get( layerDef.uid );
	}

	public function tidy(p:ProjectData) {
		_project = p;
		// Remove layerInstances without layerDefs
		for(e in layerInstances.keyValueIterator())
			if( e.value.def==null )
				layerInstances.remove(e.key);

		// Create missing layerInstances
		for(ld in _project.defs.layers)
			if( !layerInstances.exists(ld.uid) )
				layerInstances.set( ld.uid, new LayerInstance(_project, uid, ld.uid) );

		// Layer instances content
		for(li in layerInstances)
			li.tidy(_project);

	}

}
