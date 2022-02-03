package data;

class World {
	var _project : data.Project;

	public var iid : String;
	public var identifier : String;
	public var levels : Array<Level> = [];
	public var worldGridWidth : Int;
	public var worldGridHeight : Int;
	public var worldLayout : ldtk.Json.WorldLayout;


	public function new(p:Project, iid:String, identifier:String) {
		_project = p;
		this.iid = iid;
		this.identifier = identifier;
		worldGridWidth = p.defaultLevelWidth;
		worldGridHeight= p.defaultLevelHeight;
		worldLayout = Free;
	}

	@:keep
	public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '.$identifier (${levels.length} levels)';
	}


	public function toJson() : ldtk.Json.WorldJson {
		return {
			iid: iid,
			identifier: identifier,
			worldGridWidth: worldGridWidth,
			worldGridHeight: worldGridHeight,
			worldLayout: JsonTools.writeEnum(worldLayout, false),
			levels: levels.map( l->l.toJson() ),
		}
	}


	public static function fromJson(p:Project, json:ldtk.Json.WorldJson) : World {
		if( json.iid==null )
			json.iid = p.generateUniqueId_UUID();

		if( json.identifier==null )
			json.identifier = p.fixUniqueIdStr("World", (id)->p.isWorldIdentifierUnique(id));

		var w = new World(p, json.iid, json.identifier);
		w.iid = json.iid;
		w.identifier = json.identifier;

		w.worldGridWidth = JsonTools.readInt( json.worldGridWidth, p.defaultLevelWidth );
		w.worldGridHeight = JsonTools.readInt( json.worldGridHeight, p.defaultLevelHeight );
		w.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, Free );

		for( levelJson in json.levels )
			w.levels.push( Level.fromJson(p, levelJson) );

		return w;
	}


	public function createLevel(?insertIdx:Int) {
		var l = new Level(_project, _project.defaultLevelWidth, _project.defaultLevelHeight, _project.generateUniqueId_int(), _project.generateUniqueId_UUID());
		if( insertIdx==null )
			levels.push(l);
		else
			levels.insert(insertIdx,l);
		_project.quickLevelAccess.set(l.uid, l);

		l.identifier = _project.fixUniqueIdStr("Level1", (id)->_project.isLevelIdentifierUnique(id));

		tidy(_project); // this will create layer instances
		return l;
	}

	public function duplicateLevel(l:data.Level) {
		var copy : data.Level = Level.fromJson( _project, l.toJson() );

		// Remap IDs
		copy.iid = _project.generateUniqueId_UUID();
		copy.uid = _project.generateUniqueId_int();
		for(li in copy.layerInstances)
			li.levelId = copy.uid;

		// Pick unique identifier
		copy.identifier = _project.fixUniqueIdStr(l.identifier, (id)->_project.isLevelIdentifierUnique(id));

		levels.insert( dn.Lib.getArrayIndex(l,levels)+1, copy );
		_project.quickLevelAccess.set(copy.uid, l);
		tidy(_project);
		return copy;
	}

	public inline function getLowestLevelDepth() {
		var d = 0;
		for(l in levels)
			d = M.imin(d, l.worldDepth);
		return d;
	}

	public inline function getHighestLevelDepth() {
		var d = 0;
		for(l in levels)
			d = M.imax(d, l.worldDepth);
		return d;
	}

	public inline function countLevelsInDepth(d:Int) {
		var n = 0;
		for(l in levels)
			if( l.worldDepth==d )
				n++;
		return n;
	}

	public function canMoveLevelToDepthFurther(l:Level) {
		if( l.worldDepth<getHighestLevelDepth() )
			return true;
		else {
			// Check if there's any level further this one, or at least in same depth
			for(ol in levels)
				if( ol!=l && ol.worldDepth==l.worldDepth )
					return true;
			return false;
		}
	}

	public function moveLevelToDepthFurther(l:Level) {
		if( canMoveLevelToDepthFurther(l) ) {
			l.worldDepth++;

			// Shift empty first depth
			while( countLevelsInDepth(0)==0 )
				for(ol in levels)
					ol.worldDepth--;

			return true;
		}
		else
			return false;
	}


	public function canMoveLevelToDepthCloser(l:Level) {
		if( l.worldDepth>getLowestLevelDepth() )
			return true;
		else {
			// Check if there's any other level in current depth
			for(ol in levels)
				if( ol!=l && ol.worldDepth==l.worldDepth )
					return true;

			return false;
		}
	}

	public function moveLevelToDepthCloser(l:Level) {
		if( canMoveLevelToDepthCloser(l) ) {
			l.worldDepth--;
			return true;
		}
		else
			return false;
	}

	public function removeLevel(l:Level) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		for(li in l.layerInstances)
		for(ei in li.entityInstances) {
			_project.removeAnyFieldRefsTo(ei);
			_project.unregisterEntityIid(ei.iid);
			_project.unregisterAllReverseIidRefsFor(ei);
		}

		_project.quickLevelAccess.remove(l.uid);
		tidy(_project);
	}

	public inline function getLevel(uid:Int) : Null<Level> {
		return _project.quickLevelAccess.get(uid);
	}

	public function getLevelAt(worldX:Int, worldY:Int) : Null<Level> {
		for(l in levels)
			if( l.isWorldOver(worldX, worldY) )
				return l;
		return null;
	}


	public function getLevelIndex(?l:Level, ?uid:Int) : Int {
		var i = 0;
		for(ol in levels)
			if( l!=null && ol==l || uid!=null && ol.uid==uid )
				return i;
			else
				i++;
		return -1;
	}

	public function getLevelUsingLayerInst(li:data.inst.LayerInstance) : Null<data.Level> {
		for(l in levels)
		for(lli in l.layerInstances)
			if( lli==li )
				return l;

		return null;
	}

	public function getLevelUsingFieldInst(fi:data.inst.FieldInstance) : Null<data.Level> {
		for(l in levels)
		for(lfi in l.fieldInstances)
			if( lfi==fi )
				return l;

		return null;
	}

	public function getClosestLevelFrom(level:data.Level) : Null<data.Level> {
		var dh = new dn.DecisionHelper(levels);
		dh.removeValue(level);
		dh.score( (l)->-level.getBoundsDist(l) );
		return dh.getBest();
	}

	public function sortLevel(from:Int, to:Int) : Null<data.Level> {
		if( from<0 || from>=levels.length || from==to )
			return null;

		if( to<0 || to>=levels.length )
			return null;

		tidy(_project);

		var moved = levels.splice(from,1)[0];
		levels.insert(to, moved);
		_project.reorganizeWorld();
		return moved;
	}




	public function tidy(p:Project) {
		_project = p;
		for( l in levels )
			l.tidy(p);
	}
}