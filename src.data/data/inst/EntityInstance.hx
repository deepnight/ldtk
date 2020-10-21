package data.inst;

class EntityInstance {
	public var _project : Project;
	public var def(get,never) : data.def.EntityDef; inline function get_def() return _project.defs.getEntityDef(defUid);

	public var defUid(default,null) : Int;
	public var x : Int;
	public var y : Int;
	public var fieldInstances : Map<Int, data.inst.FieldInstance> = new Map();

	public var left(get,never) : Int; inline function get_left() return Std.int( x - def.width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + def.width-1;
	public var top(get,never) : Int; inline function get_top() return Std.int( y - def.height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + def.height-1;


	public function new(p:Project, entityDefUid:Int) {
		_project = p;
		defUid = entityDefUid;
	}

	@:keep public function toString() {
		return 'Instance<${def.identifier}>@$x,$y';
	}

	public function toJson(li:data.inst.LayerInstance) : led.Json.EntityInstanceJson {
		var fieldsJson = [];
		for(fi in fieldInstances)
			fieldsJson.push( fi.toJson() );

		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__grid: [ getCx(li.def), getCy(li.def) ],
			__tile: {
				var t = getSmartTile();
				if( t!=null ) {
					var td = _project.defs.getTilesetDef(t.tilesetUid);
					{
						tilesetUid: t.tilesetUid,
						srcRect: [ td.getTileSourceX(t.tileId), td.getTileSourceY(t.tileId), td.tileGridSize, td.tileGridSize ],
					}
				}
				else
					null;
			},

			defUid: defUid,
			px: [x,y],
			fieldInstances: fieldsJson,
		}
	}

	public static function fromJson(project:Project, json:led.Json.EntityInstanceJson) {
		// Convert old coordinates
		if( (cast json).x!=null )
			json.px = [ JsonTools.readInt( (cast json).x, 0 ), JsonTools.readInt((cast json).y,0) ];

		var ei = new EntityInstance(project, JsonTools.readInt(json.defUid));
		ei.x = JsonTools.readInt( json.px[0], 0 );
		ei.y = JsonTools.readInt( json.px[1], 0 );

		for( fieldJson in JsonTools.readArray(json.fieldInstances) ) {
			var fi = FieldInstance.fromJson(project, fieldJson);
			ei.fieldInstances.set(fi.defUid, fi);
		}

		return ei;
	}

	public function getCx(ld:data.def.LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:data.def.LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCellCenterX(ld:data.def.LayerDef) {
		return ( getCx(ld)+0.5 ) * ld.gridSize - x;
	}

	public function getCellCenterY(ld:data.def.LayerDef) {
		return ( getCy(ld)+0.5 ) * ld.gridSize - y;
	}

	public function isOver(layerX:Int, layerY:Int, pad=0) {
		return layerX >= left-pad && layerX <= right+pad && layerY >= top-pad && layerY <= bottom+pad;
	}

	public function getSmartColor(bright:Bool) {
		for(fi in fieldInstances) {
			if( fi.def.type==F_Color )
				for(i in 0...fi.getArrayLength())
					if( !fi.valueIsNull(i) )
						return bright ? dn.Color.toWhite(fi.getColorAsInt(i), 0.5) : fi.getColorAsInt(i);
		}
		return bright ? dn.Color.toWhite(def.color, 0.5) : def.color;
	}

	public function getSmartTile() : Null<{ tilesetUid:Int, tileId:Int }> {
		for(fi in fieldInstances)
			switch fi.def.type {
				case F_Enum(enumDefUid):
					if( fi.def.editorDisplayMode==EntityTile && !fi.valueIsNull(0) ) {
						var ed = _project.defs.getEnumDef(enumDefUid);
						if( ed.iconTilesetUid!=null )
							return {
								tilesetUid: ed.iconTilesetUid,
								tileId: ed.getValue( fi.getEnumValue(0) ).tileId,
							}
					}
				case _:
			}

		if( def.isTileDefined() )
			return {
				tilesetUid: def.tilesetId,
				tileId: def.tileId,
			}
		else
			return null;
	}

	public function tidy(p:data.Project, li:LayerInstance) {
		_project = p;

		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null ) {
				App.LOG.add("tidy", 'Removed lost fieldInstance in $this');
				fieldInstances.remove(e.key);
			}

		for(fi in fieldInstances)
			fi.tidy(_project, li, this);
	}


	public function hasAnyFieldError() {
		for(fi in fieldInstances)
			if( fi.hasAnyErrorInValues() )
				return true;
		return false;
	}


	// ** FIELDS **********************************

	public function getFieldInstance(fieldDef:data.def.FieldDef) {
		if( !fieldInstances.exists(fieldDef.uid) )
			fieldInstances.set(fieldDef.uid, new data.inst.FieldInstance(_project, fieldDef.uid));
		return fieldInstances.get( fieldDef.uid );
	}

	public function getFieldInstancesOfType(type:data.LedTypes.FieldType) {
		var all = [];
		for(fi in fieldInstances)
			if( fi.def.type.getIndex() == type.getIndex() )
				all.push(fi);
		return all;
	}
}