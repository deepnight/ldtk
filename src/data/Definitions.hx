package data;

class Definitions implements ISerializable {
	public var layers: Array<LayerDef> = [];
	public var entities: Array<EntityDef> = [];
	var project : ProjectData;

	public function new(project:ProjectData) {
		this.project = project;
	}

	public function clone() {
		return fromJson( project, toJson() );
	}

	public function toJson() : Dynamic {
		return {} // TODO
	}

	public static function fromJson(p:ProjectData, json:Dynamic) {
		var d = new Definitions(p);
		return d;
	}

	/**  LAYER DEFS  *****************************************/

	public function getLayerDef(uid:Int) : Null<LayerDef> {
		for(ld in layers)
			if( ld.uid==uid )
				return ld;
		return null;
	}

	public function createLayerDef(type:LayerType, ?name:String) : LayerDef {
		var l = new LayerDef(project.makeUniqId(), type);
		if( name!=null && isLayerNameValid(name) )
			l.name = name;
		l.gridSize = project.defaultGridSize;
		layers.push(l);
		project.tidy();
		return l;
	}

	public function isLayerNameValid(name:String) {
		for(ld in layers)
			if( ld.name==name )
				return false;
		return true;
	}

	public function removeLayerDef(ld:LayerDef) {
		if( !layers.remove(ld) )
			throw "Unknown layerDef";

		project.tidy();
	}

	public function sortLayerDef(from:Int, to:Int) : Null<LayerDef> {
		if( from<0 || from>=layers.length || from==to )
			return null;

		if( to<0 || to>=layers.length )
			return null;

		project.tidy();

		var moved = layers.splice(from,1)[0];
		layers.insert(to, moved);
		return moved;
	}



	/**  ENTITY DEFS  *****************************************/

	public function getEntityDef(uid:Int) : Null<EntityDef> {
		for(ed in entities)
			if( ed.uid==uid )
				return ed;
		return null;
	}

	public function createEntityDef(?name:String) : EntityDef {
		var ed = new EntityDef(project.makeUniqId());
		entities.push(ed);

		ed.setPivot( project.defaultPivotX, project.defaultPivotY );

		if( isEntityNameValid(name) )
			ed.name = name;

		return ed;
	}

	public function removeEntityDef(ed:EntityDef) {
		entities.remove(ed);
		project.tidy();
	}

	public function isEntityNameValid(name:String) {
		if( name==null || name.length==0 )
			return false;

		for(ed in entities)
			if( ed.name==name )
				return false;
		return true;
	}

	public function sortEntityDef(from:Int, to:Int) : Null<EntityDef> {
		if( from<0 || from>=entities.length || from==to )
			return null;

		if( to<0 || to>=entities.length )
			return null;

		project.tidy();

		var moved = entities.splice(from,1)[0];
		entities.insert(to, moved);

		return moved;
	}



	/**  FIELD DEFS  *****************************************/

	public function getFieldDef(id:Int) : Null<FieldDef> {
		for(ed in entityDefs)
		for(fd in ed.fieldDefs)
			if( fd.uid==id )
				return fd;

		return null;
	}

}