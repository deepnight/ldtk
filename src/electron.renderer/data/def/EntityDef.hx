package data.def;

import data.DataTypes;

class EntityDef {
	var _project : Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;

	public var identifier(default,set) : String;
	public var tags : Tags;
	public var exportToToc : Bool;
	public var allowOutOfBounds : Bool;
	public var doc: Null<String>;

	public var width : Int;
	public var height : Int;
	public var color : UInt;
	public var tileOpacity : Float;
	public var fillOpacity : Float;
	public var lineOpacity : Float;
	public var showName : Bool;
	public var renderMode : ldtk.Json.EntityRenderMode;
	public var tileRenderMode : ldtk.Json.EntityTileRenderMode;
	public var nineSliceBorders : Array<Int>;
	public var tilesetId : Null<Int>;
	public var tileRect : Null<ldtk.Json.TilesetRect>;
	public var uiTileRect : Null<ldtk.Json.TilesetRect>;
	public var _oldTileId : Null<Int>;

	public var hollow : Bool;

	public var resizableX : Bool;
	public var resizableY : Bool;
	public var minWidth : Null<Int>;
	public var maxWidth : Null<Int>;
	public var minHeight : Null<Int>;
	public var maxHeight : Null<Int>;
	public var keepAspectRatio : Bool;
	public var pivotX(default,set) : Float;
	public var pivotY(default,set) : Float;

	public var maxCount : Int;
	public var limitScope : ldtk.Json.EntityLimitScope;
	public var limitBehavior : ldtk.Json.EntityLimitBehavior; // what to do when maxCount is reached

	public var fieldDefs : Array<data.def.FieldDef> = [];


	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		color = Const.suggestNiceColor( _project.defs.entities.map(ed->ed.color) );
		tileOpacity = 1;
		fillOpacity = 1;
		lineOpacity = 1;
		renderMode = Rectangle;
		width = p.defaultEntityWidth;
		height = p.defaultEntityHeight;
		maxCount = 0;
		showName = true;
		limitBehavior = MoveLastOne;
		limitScope = PerLevel;
		tileRenderMode = FitInside;
		nineSliceBorders = [];
		identifier = "Entity"+uid;
		setPivot(0.5,1);
		resizableX = resizableY = false;
		keepAspectRatio = false;
		hollow = false;
		tags = new Tags();
		exportToToc = false;
		allowOutOfBounds = false;
	}

	public function isTileDefined() {
		return tilesetId!=null && tileRect!=null;
	}

	public function getDefaultTile() : Null<ldtk.Json.TilesetRect> {
		// Look inside fields defaults
		for( fd in fieldDefs )
			switch fd.type {
				case F_Tile:
					if( fd.editorDisplayMode==EntityTile ) {
						var rect = fd.getTileRectDefaultObj();
						if( rect!=null )
							return rect;
					}

				case _:
			}

		// Check display tile from entity def
		if( isTileDefined() )
			return tileRect;
		else
			return null;
	}

	function set_identifier(id:String) {
		return identifier = Project.isValidIdentifier(id) ? Project.cleanupIdentifier(id, _project.identifierStyle) : identifier;
	}

	@:keep public function toString() {
		return 'EntityDef "$identifier",($width x $height) {'
			+ fieldDefs.map( function(fd) return fd.identifier ).join(",")
			+ "}";
	}

	public inline function isResizable() return resizableX || resizableY;

	// public function getShortIdentifier(maxlen=8) {
	// 	if( identifier.length<=maxlen )
	// 		return identifier;

	// 	var dropReg = ~/[aeiouy0-9_-]/gi;
	// 	var base = 4;
	// 	return
	// 		identifier.charAt(0)
	// 		+ identifier.substr(1,base-1)
	// 		+ dropReg.replace( identifier.substr(base), "" ).substr(0,maxlen-base-1)
	// 		+ identifier.charAt( identifier.length-1 );
	// }

	public static function fromJson(p:Project, json:ldtk.Json.EntityDefJson) {
		if( (cast json).name!=null ) json.identifier = (cast json).name;
		if( (cast json).maxPerLevel!=null ) json.maxCount = (cast json).maxPerLevel;

		// Init new 1.0 opacity settings
		if( json.tileOpacity==null ) {
			if( json.hollow ) {
				json.tileOpacity = 0.25;
				json.fillOpacity = 0.15;
			}
			else {
				switch JsonTools.readEnum(ldtk.Json.EntityRenderMode, json.renderMode, false, Rectangle) {
					case Rectangle, Ellipse, Cross:
					case Tile:
						json.tileOpacity = json.fillOpacity;
						json.fillOpacity = 0.08;
						json.lineOpacity = 0;
				}
			}
		}

		var o = new EntityDef(p, JsonTools.readInt(json.uid) );
		o.identifier = JsonTools.readString( json.identifier );
		o.width = JsonTools.readInt( json.width, 16 );
		o.height = JsonTools.readInt( json.height, 16 );
		o.resizableX = JsonTools.readBool( json.resizableX, false );
		o.resizableY = JsonTools.readBool( json.resizableY, false );
		o.minWidth = JsonTools.readNullableInt( json.minWidth );
		o.maxWidth = JsonTools.readNullableInt( json.maxWidth );
		o.minHeight = JsonTools.readNullableInt( json.minHeight );
		o.maxHeight = JsonTools.readNullableInt( json.maxHeight );
		o.keepAspectRatio = JsonTools.readBool( json.keepAspectRatio, false );
		o.doc = JsonTools.unescapeString( json.doc );

		o.hollow = JsonTools.readBool( json.hollow, false );

		o.tags = Tags.fromJson(json.tags);
		o.exportToToc = JsonTools.readBool( json.exportToToc, false );
		o.allowOutOfBounds = JsonTools.readBool( json.allowOutOfBounds, false );

		o.color = JsonTools.readColor( json.color, 0x0 );
		o.tileOpacity = JsonTools.readFloat( json.tileOpacity, 1 );
		o.fillOpacity = JsonTools.readFloat( json.fillOpacity, 1 );
		o.lineOpacity = JsonTools.readFloat( json.lineOpacity, 1 );
		o.renderMode = JsonTools.readEnum(ldtk.Json.EntityRenderMode, json.renderMode, false, Rectangle);
		o.showName = JsonTools.readBool(json.showName, true);
		o.tilesetId = JsonTools.readNullableInt(json.tilesetId);
		o._oldTileId = JsonTools.readNullableInt(json.tileId);
		o.tileRect = JsonTools.readTileRect(json.tileRect, true);
		if( o.tileRect!=null && o.tileRect.tilesetUid==null )
			o.tileRect.tilesetUid = o.tilesetId;
		o.uiTileRect = JsonTools.readTileRect(json.uiTileRect, true);

		if( (cast json.tileRenderMode)=="Crop" ) json.tileRenderMode = cast "Cover";
		o.tileRenderMode = JsonTools.readEnum(ldtk.Json.EntityTileRenderMode, json.tileRenderMode, false, FitInside);
		o.nineSliceBorders = JsonTools.readArray(json.nineSliceBorders, []);
		if( o.tileRenderMode==NineSlice && o.nineSliceBorders.length!=4 )
			o.nineSliceBorders = [2,2,2,2];

		o.maxCount = JsonTools.readInt( json.maxCount, 0 );
		o.pivotX = JsonTools.readFloat( json.pivotX, 0 );
		o.pivotY = JsonTools.readFloat( json.pivotY, 0 );

		o.limitScope = JsonTools.readEnum(ldtk.Json.EntityLimitScope, json.limitScope, false, PerLevel);
		o.limitBehavior = JsonTools.readEnum( ldtk.Json.EntityLimitBehavior, json.limitBehavior, true, MoveLastOne );
		if( JsonTools.readBool( (cast json).discardExcess, true)==false )
			o.limitBehavior = PreventAdding;

		for(defJson in JsonTools.readArray(json.fieldDefs) )
			o.fieldDefs.push( FieldDef.fromJson(p, defJson) );

		return o;
	}

	public function toJson(p:Project) : ldtk.Json.EntityDefJson {
		return {
			identifier: identifier,
			uid: uid,
			tags: tags.toJson(),
			exportToToc: exportToToc,
			allowOutOfBounds: allowOutOfBounds,
			doc: JsonTools.escapeNullableString(doc),

			width: width,
			height: height,
			resizableX: resizableX,
			resizableY: resizableY,
			minWidth: minWidth,
			maxWidth: maxWidth,
			minHeight: minHeight,
			maxHeight: maxHeight,
			keepAspectRatio: keepAspectRatio,
			tileOpacity: JsonTools.writeFloat(tileOpacity),
			fillOpacity: JsonTools.writeFloat(fillOpacity),
			lineOpacity: JsonTools.writeFloat(lineOpacity),

			hollow: hollow,

			color: JsonTools.writeColor(color),
			renderMode: JsonTools.writeEnum(renderMode, false),
			showName: showName,
			tilesetId: tilesetId,
			tileRenderMode: JsonTools.writeEnum(tileRenderMode, false),
			tileRect: JsonTools.writeTileRect(tileRect),
			uiTileRect: JsonTools.writeTileRect(uiTileRect),
			nineSliceBorders: tileRenderMode==NineSlice ? nineSliceBorders.copy() : [],

			maxCount: maxCount,
			limitScope: JsonTools.writeEnum(limitScope, false),
			limitBehavior: JsonTools.writeEnum(limitBehavior, false),
			pivotX: JsonTools.writeFloat( pivotX ),
			pivotY: JsonTools.writeFloat( pivotY ),

			fieldDefs: fieldDefs.map( function(fd) return fd.toJson() ),
		}
	}


	public inline function setPivot(x,y) {
		pivotX = x;
		pivotY = y;
	}

	inline function set_pivotX(v) return pivotX = v;
	inline function set_pivotY(v) return pivotY = v;
	// inline function set_pivotX(v) return pivotX = dn.M.fclamp(v, 0, 1);
	// inline function set_pivotY(v) return pivotY = dn.M.fclamp(v, 0, 1);



	/** FIELDS ****************************/

	public function createFieldDef(project:Project, type:ldtk.Json.FieldType, baseName:String, isArray:Bool) : FieldDef {
		var f = new FieldDef(project, project.generateUniqueId_int(), type, isArray);
		f.identifier = project.fixUniqueIdStr( baseName + (isArray?"_array":""), Free, (id)->isFieldIdentifierUnique(id) );
		fieldDefs.push(f);
		return f;
	}

	public function sortField(from:Int, to:Int) : Null<FieldDef> {
		if( from<0 || from>=fieldDefs.length || from==to )
			return null;

		if( to<0 || to>=fieldDefs.length )
			return null;

		var moved = fieldDefs.splice(from,1)[0];
		fieldDefs.insert(to, moved);

		return moved;
	}

	public function getFieldDef(id:haxe.extern.EitherType<String,Int>) : Null<FieldDef> {
		for(fd in fieldDefs)
			if( fd.uid==id || fd.identifier==id )
				return fd;

		return null;
	}

	public function isFieldIdentifierUnique(id:String) {
		id = Project.cleanupIdentifier(id,Free);
		for(fd in fieldDefs)
			if( fd.identifier==id )
				return false;
		return true;
	}


	public function tidy(p:data.Project) {
		_project = p;

		// Migrate old tileId to tileRect
		if( _oldTileId!=null && tileRect==null ) {
			var td = p.defs.getTilesetDef(tilesetId);
			if( td!=null )
				tileRect = td.getTileRectFromTileIds([ _oldTileId ]);
		}

		// Tags
		tags.tidy();

		// Lost tileset
		if( tilesetId!=null && p.defs.getTilesetDef(tilesetId)==null ) {
			App.LOG.add("tidy", 'Removed lost tileset of $this');
			tilesetId = null;
			renderMode = Rectangle;
		}

		// Field defs
		Definitions.tidyFieldDefsArray(p, fieldDefs, this.toString());
	}
}