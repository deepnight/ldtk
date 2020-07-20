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
			layerInstances.push( new led.inst.LayerInstance(_project, uid, ld.identifier) );
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id,true) : identifier;
	}

	@:keep public function toString() {
		return Type.getClassName(Type.getClass(this));
	}

	public function toJson() {
		var layersJson = [];
		for(li in layerInstances)
			layersJson.push( li.toJson() );

		return {
			uid: uid,
			identifier: identifier,
			pxWid: pxWid,
			pxHei: pxHei,
			layerInstances : layersJson,
		}
	}

	public static function fromJson(p:Project, json:Dynamic) {
		var l = new Level( p, JsonTools.readInt(json.uid) );
		l.pxWid = JsonTools.readInt( json.pxWid, Project.DEFAULT_LEVEL_WIDTH );
		l.pxHei = JsonTools.readInt( json.pxHei, Project.DEFAULT_LEVEL_HEIGHT );
		l.identifier = JsonTools.readString(json.identifier, "Level"+l.uid);

		for( layerJson in JsonTools.readArray(json.layerInstances) ) {
			var li = led.inst.LayerInstance.fromJson(p, layerJson);
			l.layerInstances.push(li);
		}

		return l;
	}

	public inline function inBounds(x:Int, y:Int) {
		return x>=0 && x<pxWid && y>=0 && y<pxHei;
	}

	public function getLayerInstance(?id:String, ?layerDef:led.def.LayerDef) : Null<led.inst.LayerInstance> {
		if( id==null && layerDef==null )
			throw "Need 1 parameter";

		if( id==null )
			id = layerDef.identifier;

		for(li in layerInstances)
			if( li.layerDefId==id )
				return li;

		return null;
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

		// Create missing layerInstances (NOTE: this array is assumed to be sorted)
		var i = 0;
		while( i<_project.defs.layers.length ) {
			var ld = _project.defs.layers[i];
			if( i>=layerInstances.length || layerInstances[i].layerDefId!=ld.identifier )
				layerInstances.insert(i, new led.inst.LayerInstance(_project, uid, ld.identifier));
			i++;
		}

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
