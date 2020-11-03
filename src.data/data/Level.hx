package data;

class Level {
	var _project : Project;

	@:allow(data.Project)
	public var uid(default,null) : Int;
	public var identifier(default,set): String;
	public var pxWid : Int;
	public var pxHei : Int;
	public var layerInstances : Array<data.inst.LayerInstance> = [];


	@:allow(data.Project)
	private function new(project:Project, uid:Int) {
		this.uid = uid;
		pxWid = Project.DEFAULT_LEVEL_WIDTH;
		pxHei = Project.DEFAULT_LEVEL_HEIGHT;
		this._project = project;
		this.identifier = "Level"+uid;

		for(ld in _project.defs.layers)
			layerInstances.push( new data.inst.LayerInstance(_project, uid, ld.uid) );
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	@:keep public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '.$identifier(#$uid)';
	}

	public function toJson() : ldtk.Json.LevelJson {
		return {
			identifier: identifier,
			uid: uid,
			pxWid: pxWid,
			pxHei: pxHei,
			layerInstances: layerInstances.map( function(li) return li.toJson() ),
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.LevelJson) {
		var l = new Level( p, JsonTools.readInt(json.uid) );
		l.pxWid = JsonTools.readInt( json.pxWid, Project.DEFAULT_LEVEL_WIDTH );
		l.pxHei = JsonTools.readInt( json.pxHei, Project.DEFAULT_LEVEL_HEIGHT );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);

		l.layerInstances = [];
		for( layerJson in JsonTools.readArray(json.layerInstances) ) {
			var li = data.inst.LayerInstance.fromJson(p, layerJson);
			l.layerInstances.push(li);
		}

		return l;
	}

	public inline function inBounds(x:Int, y:Int) {
		return x>=0 && x<pxWid && y>=0 && y<pxHei;
	}

	public function getLayerInstance(?layerDefUid:Int, ?layerDef:data.def.LayerDef) : data.inst.LayerInstance {
		if( layerDefUid==null && layerDef==null )
			throw "Need 1 parameter";

		if( layerDefUid==null )
			layerDefUid = layerDef.uid;

		for(li in layerInstances)
			if( li.layerDefUid==layerDefUid )
				return li;

		throw "Missing layer instance for "+layerDefUid;
	}

	public function getLayerInstanceFromRule(r:data.def.AutoLayerRuleDef) {
		var ld = _project.defs.getLayerDefFromRule(r);
		return ld!=null ? getLayerInstance(ld) : null;
	}

	public function getLayerInstanceFromEntity(?ei:data.inst.EntityInstance, ?ed:data.def.EntityDef) : Null<data.inst.LayerInstance> {
		if( ei==null && ed==null )
			return null;

		for(li in layerInstances)
		for(e in li.entityInstances)
			if( ei!=null && e==ei || ed!=null && e.defUid==ed.uid )
				return li;

		return null;
	}

	public function tidy(p:Project) {
		_project = p;

		// Remove layerInstances without layerDefs
		var i = 0;
		while( i<layerInstances.length )
			if( layerInstances[i].def==null ) {
				App.LOG.add("tidy", 'Removed lost layer instance in $this');
				layerInstances.splice(i,1);
			}
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
					else {
						App.LOG.add("tidy", 'Added missing layer instance ${ld.identifier} in $this');
						layerInstances.push( new data.inst.LayerInstance(_project, uid, ld.uid) );
					}
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


	public function hasAnyError() {
		for(li in layerInstances)
			switch li.def.type {
				case IntGrid:
				case Entities:
					for(ei in li.entityInstances)
						if( ei.hasAnyFieldError() )
							return true;

				case Tiles:
				case AutoLayer:
			}

		return false;
	}



	/** RENDERING *******************/

	public function iterateLayerInstancesInRenderOrder( eachLayer:data.inst.LayerInstance->Void ) {
		var i = _project.defs.layers.length-1;
		while( i>=0 ) {
			eachLayer( getLayerInstance(_project.defs.layers[i]) );
			i--;
		}
	}
}
