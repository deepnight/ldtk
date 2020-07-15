package led;

class Level {
	var _project : Project;

	public var uid(default,null) : Int;
	public var customName: Null<String>; // TODO save
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Map<Int,led.inst.LayerInstance> = new Map();


	@:allow(led.Project)
	private function new(project:Project, uid:Int) {
		this.uid = uid;
		pxWid = Project.DEFAULT_LEVEL_WIDTH;
		pxHei = Project.DEFAULT_LEVEL_HEIGHT;
		this._project = project;

		for(ld in _project.defs.layers)
			layerInstances.set( ld.uid, new led.inst.LayerInstance(_project, uid, ld.uid) );
	}

	public inline function getName() return customName!=null ? customName : getDefaultName();

	public function getDefaultName() return "Level#"+uid;

	@:keep public function toString() {
		return Type.getClassName(Type.getClass(this));
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
			customName: customName,
		}
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var l = new Level( p, JsonTools.readInt(json.uid) );
		l.pxWid = JsonTools.readInt( json.pxWid, Project.DEFAULT_LEVEL_WIDTH );
		l.pxHei = JsonTools.readInt( json.pxHei, Project.DEFAULT_LEVEL_HEIGHT );
		l.customName = json.customName;

		for( layerJson in JsonTools.readArray(json.layerInstances) ) {
			var li = led.inst.LayerInstance.fromJson(p, layerJson);
			l.layerInstances.set(li.layerDefId, li);
		}

		return l;
	}

	public inline function inBounds(x:Int, y:Int) {
		return x>=0 && x<pxWid && y>=0 && y<pxHei;
	}

	public function getLayerInstance(?name:String, ?layerDef:led.def.LayerDef) : led.inst.LayerInstance {
		if( name==null && layerDef==null )
			throw "Need 1 parameter";

		if( name!=null ) {
			for(li in layerInstances)
				if( li.def.name==name )
					return li;
			throw "Unknown layer "+name;
		}
		else if( !layerInstances.exists(layerDef.uid) )
			throw "Missing layer instance for "+layerDef.name;
		else
			return layerInstances.get( layerDef.uid );
	}

	public function tidy(p:Project) {
		_project = p;
		// Remove layerInstances without layerDefs
		for(e in layerInstances.keyValueIterator())
			if( e.value.def==null )
				layerInstances.remove(e.key);

		// Create missing layerInstances
		for(ld in _project.defs.layers)
			if( !layerInstances.exists(ld.uid) )
				layerInstances.set( ld.uid, new led.inst.LayerInstance(_project, uid, ld.uid) );

		// Layer instances content
		for(li in layerInstances)
			li.tidy(_project);
	}


	public function applyNewBounds(newPxLeft:Int, newPxTop:Int, newPxWid:Int, newPxHei:Int) {
		for(li in layerInstances)
			li.applyNewBounds(newPxLeft, newPxTop, newPxWid, newPxHei);
		pxWid = newPxWid;
		pxHei = newPxHei;
		_project.tidy();
	}



	/** RENDERING *******************/

	public function iterateLayerInstancesInRenderOrder( eachLayer:led.inst.LayerInstance->Void ) {
		var i = _project.defs.layers.length-1;
		while( i>=0 ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i--;
		}
	}

	#if heaps

	public function renderAllLayers(target:h2d.Object) {
		iterateLayerInstancesInRenderOrder( function(li) {
			li.render(target);
		});
	}

	#else

	@:deprecated("Not implemented on this platform")
	public function renderAllLayers(target:Dynamic) {}

	#end
}
