package led.inst;

class EntityInstance {
	public var _project : Project;
	public var def(get,never) : led.def.EntityDef; inline function get_def() return _project.defs.getEntityDef(defUid);

	public var defUid(default,null) : Int;
	public var x : Int;
	public var y : Int;
	public var fieldInstances : Map<Int, led.inst.FieldInstance> = new Map();

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

	public function toJson(li:led.inst.LayerInstance) : led.Json.EntityInstanceJson {
		var fieldsJson = [];
		for(fi in fieldInstances)
			fieldsJson.push( fi.toJson() );

		return {
			// Fields preceded by "__" are only exported to facilitate parsing
			__identifier: def.identifier,
			__cx: getCx(li.def),
			__cy: getCy(li.def),

			defUid: defUid,
			x: x,
			y: y,
			fieldInstances: fieldsJson,

		}
	}

	public static function fromJson(project:Project, json:Dynamic) {
		var ei = new EntityInstance(project, JsonTools.readInt(json.defUid));
		ei.x = JsonTools.readInt( json.x, 0 );
		ei.y = JsonTools.readInt( json.y, 0 );

		for( fieldJson in JsonTools.readArray(json.fieldInstances) ) {
			var fi = FieldInstance.fromJson(project, fieldJson);
			ei.fieldInstances.set(fi.defUid, fi);
		}

		return ei;
	}

	public function getCx(ld:led.def.LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:led.def.LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCellCenterX(ld:led.def.LayerDef) {
		return ( getCx(ld)+0.5 ) * ld.gridSize - x;
	}

	public function getCellCenterY(ld:led.def.LayerDef) {
		return ( getCy(ld)+0.5 ) * ld.gridSize - y;
	}

	public function isOver(levelX:Int, levelY:Int, pad=0) {
		return levelX >= left-pad && levelX <= right+pad && levelY >= top-pad && levelY <= bottom+pad;
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

	public function getTileOverrideFromFields() {
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

		return null;
	}

	public function tidy(p:led.Project) {
		_project = p;

		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null )
				fieldInstances.remove(e.key);

		for(fi in fieldInstances)
			fi.tidy(_project);
	}


	// ** FIELDS **********************************

	public function getFieldInstance(fieldDef:led.def.FieldDef) {
		if( !fieldInstances.exists(fieldDef.uid) )
			fieldInstances.set(fieldDef.uid, new led.inst.FieldInstance(_project, fieldDef.uid));
		return fieldInstances.get( fieldDef.uid );
	}

	// public function getStringField(name:String) : Null<String> {
	// 	var fd = def.getFieldDef(name);
	// 	fd.require(F_String);
	// 	return getFieldInstance(fd).getString();
	// }

	// public function getFloatField(name:String) : Null<Float> {
	// 	var fd = def.getFieldDef(name);
	// 	fd.require(F_Float);
	// 	return getFieldInstance(fd).getFloat();
	// }

	// public function getIntField(name:String) : Null<Int> {
	// 	var fd = def.getFieldDef(name);
	// 	fd.require(F_Int);
	// 	return getFieldInstance(fd).getInt(0); // field array
	// }

	// public function getColorField(name:String) : Null<UInt> {
	// 	var fd = def.getFieldDef(name);
	// 	fd.require(F_Color);
	// 	return getFieldInstance(fd).getColorAsInt();
	// }

}