package led;

class Project {
	public static var DEFAULT_LEVEL_WIDTH = 256; // px
	public static var DEFAULT_LEVEL_HEIGHT = 256; // px
	public static var DEFAULT_GRID_SIZE = 16; // px

	public static var DATA_VERSION = 1;
	/* DATA VERSION CHANGELOG:
		1. initial release
	*/


	var nextUid = 0;
	public var defs : Definitions;
	public var levels : Array<Level> = [];

	public var dataVersion : Int;
	public var name : String;
	public var defaultPivotX : Float;
	public var defaultPivotY : Float;
	public var defaultGridSize : Int;
	public var bgColor : UInt;

	private function new() {
		name = "New project";
		dataVersion = Project.DATA_VERSION;
		defaultGridSize = Project.DEFAULT_GRID_SIZE;
		bgColor = 0x7f8093;
		defaultPivotX = defaultPivotY = 0;

		defs = new Definitions(this);
	}

	public static function createEmpty() {
		var p = new Project();
		p.createLevel();

		return p;
	}

	public function makeUniqId() return nextUid++;

	@:keep public function toString() {
		return '$name(levels=${levels.length}, layerDefs=${defs.layers.length}, entDefs=${defs.entities.length})';
	}

	public static function fromJson(json:Dynamic) {
		var p = new Project();
		p.dataVersion = JsonTools.readInt(json.dataVersion, 0);
		p.nextUid = JsonTools.readInt( json.nextUid, 0 );
		p.name = JsonTools.readString( json.name );
		p.defaultPivotX = JsonTools.readFloat( json.defaultPivotX, 0 );
		p.defaultPivotY = JsonTools.readFloat( json.defaultPivotY, 0 );
		p.defaultGridSize = JsonTools.readInt( json.defaultGridSize, Project.DEFAULT_GRID_SIZE );
		p.bgColor = JsonTools.readColor( json.bgColor, 0xffffff );

		p.defs = Definitions.fromJson(p, json.defs);

		for( lvlJson in JsonTools.readArray(json.levels) )
			p.levels.push( Level.fromJson(p, lvlJson) );

		p.dataVersion = Project.DATA_VERSION; // always uses latest version
		return p;
	}

	public function toJson(excludeLevels=false) {
		return {
			name: name,
			dataVersion: dataVersion,
			defaultPivotX: JsonTools.clampFloatPrecision( defaultPivotX ),
			defaultPivotY: JsonTools.clampFloatPrecision( defaultPivotY ),
			defaultGridSize: defaultGridSize,
			bgColor: JsonTools.writeColor(bgColor),
			nextUid: nextUid,

			defs: defs.toJson(),
			levels: excludeLevels ? [] : levels.map( function(l) return l.toJson() ),
		}
	}

	public function tidy() {
		defs.tidy(this);

		for(level in levels)
			level.tidy(this);
	}

	public function loadExternalFiles(projectDir:String) {
		for(td in defs.tilesets)
			td.reloadImage(projectDir);
	}


	/**  LEVELS  *****************************************/

	public function createLevel() {
		var l = new Level(this, makeUniqId());
		levels.push(l);

		var id = "Level";
		var idx = 2;
		while( !isLevelIdentifierUnique(id) )
			id = "Level"+(idx++);
		l.identifier = id;

		tidy(); // this will create layer instances
		return l;
	}

	public function isLevelIdentifierUnique(id:String) {
		id = cleanupIdentifier(id,true);
		for(l in levels)
			if( l.identifier==id )
				return false;
		return true;
	}

	public function removeLevel(l:Level) {
		if( !levels.remove(l) )
			throw "Level not found in this Project";

		tidy();
	}

	public function getLevel(?id:String, ?uid:Int) : Null<Level> {
		for(l in levels)
			if( l.uid==uid || l.identifier==id )
				return l;
		return null;
	}

	public function sortLevel(from:Int, to:Int) : Null<led.Level> {
		if( from<0 || from>=levels.length || from==to )
			return null;

		if( to<0 || to>=levels.length )
			return null;

		tidy();

		var moved = levels.splice(from,1)[0];
		levels.insert(to, moved);
		return moved;
	}


	/**  GENERAL TOOLS  *****************************************/

	public static inline function isValidIdentifier(id:String) {
		return cleanupIdentifier(id,false) != null;
	}


	public static function cleanupIdentifier(id:String, capitalizeFirstLetter:Bool) : Null<String> {
		if( id==null )
			return null;

		id = StringTools.trim(id);

		// Replace any invalid char with "_"
		var reg = ~/([^A-Z0-9_])+/gi;
		id = reg.replace(id, "_");

		// Replace leading numbers with "_"
		reg =~/^([0-9]+)([a-z0-9_]*)$/gi;
		// if( reg.match(id) )
		id = reg.replace(id, "_$2");

		// Trim duplicates "_"
		reg = ~/([_\1]+)/gi;
		id = reg.replace(id, "_");

		// Checks identifier syntax (letters or _ )
		reg = ~/^[a-z_]+[a-z0-9_]*$/gi; // TODO not checking leading numbers
		if( reg.match(id) ) {
			if( capitalizeFirstLetter ) {
				reg = ~/^(_*)([a-z])([a-zA-Z0-9_]*)/g; // extract first letter, if it's lowercase
				if( reg.match(id) )
					id = reg.matched(1) + reg.matched(2).toUpperCase() + reg.matched(3);
			}

			return id;
		}
		else
			return null;
	}

	#if editor
	public function iterateAllFieldInstances(?searchType:led.LedTypes.FieldType, run:led.inst.FieldInstance->Void) {
		for(l in levels)
		for(li in l.layerInstances)
		for(ei in li.entityInstances)
		for(fi in ei.fieldInstances)
			if( searchType==null || fi.def.type.equals(searchType) )
				run(fi);
	}
	#end



	#if debug
	public static function createTest() : Project {
		var p = new Project();

		// Hero
		var ed = p.defs.createEntityDef();
		ed.identifier = "Hero";
		ed.color = 0x00ff00;
		ed.width = 24;
		ed.height = 32;
		ed.maxPerLevel = 1;
		ed.setPivot(0.5,1);

		// Hero.life
		var fd = ed.createFieldDef(p, F_Int);
		fd.identifier = "life";
		fd.setDefault(Std.string(3));
		fd.setMin("1");
		fd.setMax("10");

		// Collision layer
		var ld = p.defs.layers[0];
		ld.identifier = "Collisions";
		ld.getIntGridValueDef(0).name = "walls";
		ld.addIntGridValue(0x00ff00, "grass");
		ld.addIntGridValue(0x0000ff, "water");

		// Entity layer
		var ld = p.defs.createLayerDef(Entities,"Entities");

		// Decoration layer
		var ld = p.defs.createLayerDef(IntGrid,"Decorations");
		ld.gridSize = 8;
		ld.displayOpacity = 0.7;
		ld.getIntGridValueDef(0).color = 0x00ff00;

		p.tidy();

		return p;
	}
	#end
}
