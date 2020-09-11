package led;

class Level {
	var _project : Project;

	public var uid(default,null) : Int;
	public var identifier(default,set): String;
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Array<led.inst.LayerInstance> = [];


	@:allow(led.Project)
	private function new(project:Project, uid:Int) {
		this.uid = uid;
		pxWid = Project.DEFAULT_LEVEL_WIDTH;
		pxHei = Project.DEFAULT_LEVEL_HEIGHT;
		this._project = project;
		this.identifier = "Level"+uid;

		for(ld in _project.defs.layers)
			layerInstances.push( new led.inst.LayerInstance(_project, uid, ld.uid) );
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	@:keep public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function toJson() {
		return {
			identifier: identifier,
			uid: uid,
			pxWid: pxWid,
			pxHei: pxHei,
			layerInstances: layerInstances.map( function(li) return li.toJson() ),
		}
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var l = new Level( p, JsonTools.readInt(json.uid) );
		l.pxWid = JsonTools.readInt( json.pxWid, Project.DEFAULT_LEVEL_WIDTH );
		l.pxHei = JsonTools.readInt( json.pxHei, Project.DEFAULT_LEVEL_HEIGHT );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);

		l.layerInstances = [];
		for( layerJson in JsonTools.readArray(json.layerInstances) ) {
			var li = led.inst.LayerInstance.fromJson(p, layerJson);
			l.layerInstances.push(li);
		}

		return l;
	}

	public inline function inBounds(x:Int, y:Int) {
		return x>=0 && x<pxWid && y>=0 && y<pxHei;
	}

	public function getLayerInstance(?layerDefUid:Int, ?layerDef:led.def.LayerDef) : led.inst.LayerInstance {
		if( layerDefUid==null && layerDef==null )
			throw "Need 1 parameter";

		if( layerDefUid==null )
			layerDefUid = layerDef.uid;

		for(li in layerInstances)
			if( li.layerDefUid==layerDefUid )
				return li;

		throw "Missing layer instance for "+layerDefUid;
	}

	public function getLayerInstanceFromRule(r:led.def.AutoLayerRule) {
		var ld = _project.defs.getLayerDefFromRule(r);
		return getLayerInstance(ld);
	}

	public function tidy(p:Project) {
		_project = p;

		// Remove layerInstances without layerDefs
		var i = 0;
		while( i<layerInstances.length )
			if( layerInstances[i].def==null )
				layerInstances.splice(i,1);
			else
				i++;

		// Create missing layerInstances & check if they're sorted in the same order as defs
		for(i in 0..._project.defs.layers.length)
			if( i>=layerInstances.length || layerInstances[i].layerDefUid!=_project.defs.layers[i].uid ) {
				var existing = new Map();
				for(li in layerInstances)
					existing.set(li.layerDefUid, li);
				layerInstances = [];
				for(ld in _project.defs.layers)
					if( existing.exists(ld.uid) )
						layerInstances.push( existing.get(ld.uid) );
					else
						layerInstances.push( new led.inst.LayerInstance(_project, uid, ld.uid) );
				break;
			}

		// Tidy layer instances
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
}
