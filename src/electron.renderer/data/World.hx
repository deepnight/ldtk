package data;

class World {
	var _project : data.Project;

	public var iid : String;
	public var identifier : String;
	public var levels : Array<Level> = [];

	public var defaultLevelWidth : Int;
	public var defaultLevelHeight : Int;

	public var worldGridWidth : Int;
	public var worldGridHeight : Int;
	public var worldLayout : ldtk.Json.WorldLayout;



	@:allow(data.Project)
	function new(p:Project, iid:String, identifier:String) {
		_project = p;
		this.iid = iid;
		this.identifier = identifier;
		worldLayout = Free;
		defaultLevelWidth = Project.DEFAULT_LEVEL_WIDTH;
		defaultLevelHeight = Project.DEFAULT_LEVEL_HEIGHT;
		worldGridWidth = defaultLevelWidth;
		worldGridHeight= defaultLevelHeight;
	}

	@:keep
	public function toString() {
		return Type.getClassName( Type.getClass(this) ) + '.$identifier (${levels.length} levels)';
	}


	public function toJson() : ldtk.Json.WorldJson {
		return {
			iid: iid,
			identifier: identifier,
			defaultLevelWidth: defaultLevelWidth,
			defaultLevelHeight: defaultLevelHeight,
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

		w.defaultLevelWidth = JsonTools.readInt( json.defaultLevelWidth, Project.DEFAULT_LEVEL_WIDTH );
		w.defaultLevelHeight = JsonTools.readInt( json.defaultLevelHeight, Project.DEFAULT_LEVEL_HEIGHT );

		w.worldGridWidth = JsonTools.readInt( json.worldGridWidth, w.defaultLevelWidth );
		w.worldGridHeight = JsonTools.readInt( json.worldGridHeight, w.defaultLevelHeight );
		w.worldLayout = JsonTools.readEnum( ldtk.Json.WorldLayout, json.worldLayout, false, Free );

		for( levelJson in json.levels )
			w.levels.push( Level.fromJson(p, w, levelJson, true) );

		return w;
	}


	/*** WORLDS ************************************************/

	public function getWorldBounds() {
		var left = Const.INFINITE;
		var right = -Const.INFINITE;
		var top = Const.INFINITE;
		var bottom = -Const.INFINITE;

		for(l in levels) {
			left = dn.M.imin(left, l.worldX);
			right = dn.M.imax(right, l.worldX+l.pxWid);
			top = dn.M.imin(top, l.worldY);
			bottom = dn.M.imax(bottom, l.worldY+l.pxHei);
		}

		return {
			left: left,
			right: right,
			top: top,
			bottom: bottom,
		}
	}

	public inline function getWorldWidth(?ignoredLevel:data.Level) {
		var min = Const.INFINITE;
		var max = -Const.INFINITE;
		for(l in levels)
			if( l!=ignoredLevel ) {
				min = dn.M.imin(min, l.worldX);
				max = dn.M.imax(max, l.worldX+l.pxWid);
			}
		return max-min;
	}


	public inline function getWorldHeight(?ignoredLevel:data.Level) {
		var min = Const.INFINITE;
		var max = -Const.INFINITE;
		for(l in levels)
			if( l!=ignoredLevel ) {
				min = dn.M.imin(min, l.worldY);
				max = dn.M.imax(max, l.worldY+l.pxHei);
			}
		return max-min;
	}


	/*** LEVELS ************************************************/

	public function createLevel(?insertIdx:Int) {
		var l = new Level(_project, this, defaultLevelWidth, defaultLevelHeight, _project.generateUniqueId_int(), _project.generateUniqueId_UUID());
		if( insertIdx==null )
			levels.push(l);
		else
			levels.insert(insertIdx,l);

		l.identifier = _project.fixUniqueIdStr("Level1", (id)->_project.isLevelIdentifierUnique(id));

		tidy(_project); // this will create layer instances
		return l;
	}

	public function duplicateLevel(l:data.Level) {
		var copy : data.Level = Level.fromJson( _project, this, l.toJson(true), false );

		// Remap IDs
		copy.iid = _project.generateUniqueId_UUID();
		copy.uid = _project.generateUniqueId_int();
		for(li in copy.layerInstances)
			li.levelId = copy.uid;

		// Init IIDs
		var remaps = new Map();
		inline function _remap(iid:String) : String {
			var newIid = _project.generateUniqueId_UUID();
			remaps.set(iid, newIid);
			return newIid;
		}
		for(li in copy.layerInstances) {
			li.iid = _remap(li.iid);
			for( ei in li.entityInstances ) {
				ei.iid = _remap(ei.iid);
				_project.registerEntityInstance(ei);
			}
		}

		// Remap IID references in fields
		for(li in copy.layerInstances)
		for(ei in li.entityInstances)
		for(fi in ei.fieldInstances) {
			switch fi.def.type {
				case F_EntityRef:
					var i = 0;
					while( i<fi.getArrayLength() ) {
						var oldIid = fi.getEntityRefIid(i);
						if( remaps.exists(oldIid) ) {
							var tei = _project.getEntityInstanceByIid( remaps.get(oldIid) );
							fi.setEntityRefTo(i, ei, tei);
							i++;
						}
						else {
							var tei = fi.getEntityRefInstance(i);
							if( tei!=null && tei._li.levelId != copy.uid )
								fi.removeArrayValue(i);
							else
								i++;
						}
					}
				case _:
			}
		}

		// Pick unique identifier
		copy.identifier = _project.fixUniqueIdStr(l.identifier, (id)->_project.isLevelIdentifierUnique(id));

		levels.insert( dn.Lib.getArrayIndex(l,levels)+1, copy );
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

		_project.unregisterLevelQuickAccess(l);
		tidy(_project);
	}

	public inline function getLevel(uid:Int) : Null<Level> {
		return _project.getLevelAnywhere(uid);
	}

	public function getLevelAt(worldX:Int, worldY:Int) : Null<Level> {
		for(l in levels)
			if( l.isWorldOver(worldX, worldY) )
				return l;
		return null;
	}


	public function getShortName(maxLen=6) {
		if( identifier.length<=maxLen )
			return identifier;

		var short = "";
		var skipSpace = false;
		var picksAfterCaps = 2;
		var picks = picksAfterCaps;
		var lastPick = 0;
		for(i in 0...identifier.length) {
			var c = identifier.charCodeAt(i);
			if( c>="A".code && c<="Z".code || c>="0".code && c<="9".code )
				picks = picksAfterCaps;

			if( c=="_".code ) {
				picks = picksAfterCaps;
				skipSpace = true;
			}

			if( !skipSpace && picks>0 ) {
				picks--;
				short+=identifier.charAt(i);
				lastPick = i;
			}

			if( skipSpace && picks>0 && c!="_".code ) {
				picks--;
				skipSpace = false;
				short+=identifier.charAt(i).toUpperCase();
				lastPick = i;
			}
			if( short.length>=maxLen )
				return short;
		}

		// Fill in with more characters if too short
		lastPick++;
		while( lastPick<identifier.length && short.length<maxLen ) {
			short+=identifier.charAt(lastPick);
			lastPick++;
		}
		return short;
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

	public function getClosestLevelFrom(level:data.Level) : Null<data.Level> {
		var dh = new dn.DecisionHelper(levels);
		dh.discardValue(level);
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
		reorganizeWorld();
		return moved;
	}



	public function applyAutoLevelIdentifiers() {
		var oldIdentifiers = new Map();
		var uniq = 0;
		for(l in levels)
			if( l.useAutoIdentifier ) {
				oldIdentifiers.set(l.uid, l.identifier);
				l.identifier = "#"+(uniq++);
			}

		var idx = 0;
		var b = getWorldBounds();
		for(l in levels) {
			if( l.useAutoIdentifier ) {
				var id = _project.levelNamePattern;
				id = StringTools.replace(id, "%depth", Std.string(l.worldDepth));
				id = StringTools.replace(id, "%world", identifier );

				id = StringTools.replace(id, "%idx1", Std.string(idx+1) );
				id = StringTools.replace(id, "%idx", Std.string(idx) );
				id = StringTools.replace(id, "%gx", Std.string( switch worldLayout {
					case GridVania: Std.int((l.worldX-b.left) / worldGridWidth);
					case Free, LinearHorizontal, LinearVertical: "";
				}) );
				id = StringTools.replace(id, "%gy", Std.string( switch worldLayout {
					case GridVania: Std.int((l.worldY-b.top) / worldGridHeight);
					case Free, LinearHorizontal, LinearVertical: "";
				}) );
				id = StringTools.replace(id, "%x", Std.string(switch worldLayout {
					case Free, GridVania: l.worldX;
					case LinearHorizontal, LinearVertical: "";
				}) );
				id = StringTools.replace(id, "%y", Std.string(switch worldLayout {
					case Free, GridVania: l.worldY;
					case LinearHorizontal, LinearVertical: "";
				}) );
				id = StringTools.replace(id, "%d", Std.string(l.worldDepth) );
				l.identifier = _project.fixUniqueIdStr(id, id->_project.isLevelIdentifierUnique(id));

				if( oldIdentifiers.get(l.uid)!=l.identifier )
					l.invalidateJsonCache();
			}
			idx++;
		}
	}


	/**
		Auto re-arrange levels based on world layout (only affects linear modes)
	**/
	public function reorganizeWorld() {
		var spacing = 48;
		switch worldLayout {
			case Free:

			case LinearHorizontal:
				var wx = 0;
				for(l in levels) {
					l.worldX = wx;
					l.worldY = 0;
					wx += l.pxWid + spacing;
				}

			case LinearVertical:
				var wy = 0;
				for(l in levels) {
					l.worldX = 0;
					l.worldY = wy;
					wy += l.pxHei + spacing;
				}

			case GridVania:
		}

		applyAutoLevelIdentifiers();
	}


	public function snapWorldGridX(v:Int, forceGreaterThanZero:Bool) {
		return worldLayout!=GridVania ? v
		: forceGreaterThanZero
			? M.imax( M.round(v/worldGridWidth), 1 ) * worldGridWidth
			: M.round(v/worldGridWidth) * worldGridWidth;
	}

	public function snapWorldGridY(v:Int, forceGreaterThanZero:Bool) {
		return worldLayout!=GridVania ? v
		: forceGreaterThanZero
			? M.imax( M.round(v/worldGridHeight), 1 ) * worldGridHeight
			: M.round(v/worldGridHeight) * worldGridHeight;
	}


	public function onWorldGridChange(oldWid:Int, oldHei:Int) {
		for(l in levels) {
			var wcx = Std.int(l.worldX/oldWid);
			var wcy = Std.int(l.worldY/oldHei);
			l.worldX = wcx * worldGridWidth;
			l.worldY = wcy * worldGridHeight;
		}
	}


	public function onWorldLayoutChange(old:ldtk.Json.WorldLayout) {
		// Convert layout
		switch worldLayout {
			case Free:

			case GridVania:
				switch old {
					case Free:
						for(l in levels) {
							l.worldX = Std.int( l.worldX/worldGridWidth ) * worldGridWidth;
							l.worldY = Std.int( l.worldY/worldGridHeight ) * worldGridHeight;
						}

					case GridVania:

					case LinearHorizontal:
						var pos = 0;
						for(l in levels) {
							l.worldX = pos*worldGridWidth;
							pos+=dn.M.ceil( l.pxWid / worldGridWidth );
						}

					case LinearVertical:
						var pos = 0;
						for(l in levels) {
							l.worldY = pos*worldGridHeight;
							pos+=dn.M.ceil( l.pxHei / worldGridHeight );
						}
				}

			case LinearHorizontal:
			case LinearVertical:
		}

		tidy(_project); // for auto level naming
	}


	public function tidy(p:Project) {
		_project = p;

		// Fix default level width/height to match the grid
		if( worldLayout==GridVania ) {
			defaultLevelWidth = M.imax( M.round(defaultLevelWidth/worldGridWidth), 1 ) * worldGridWidth;
			defaultLevelHeight = M.imax( M.round(defaultLevelHeight/worldGridHeight), 1 ) * worldGridHeight;
		}

		for( l in levels ) {
			_project.registerLevelQuickAccess(l);
			l.tidy(p, this);
		}

		reorganizeWorld();
	}

}