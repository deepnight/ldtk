package data;

class EntityInstance {
	public var project : ProjectData;
	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return project.getEntityDef(defId);

	public var x : Int;
	public var y : Int;
	var fieldInstances : Map<Int, data.FieldInstance> = new Map();

	public var left(get,never) : Int; inline function get_left() return Std.int( x - def.width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + def.width-1;
	public var top(get,never) : Int; inline function get_top() return Std.int( y - def.height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + def.height-1;


	public function new(p:ProjectData, def:EntityDef) {
		project = p;
		defId = def.uid;
	}

	@:keep public function toString() {
		return 'Instance<${def.name}>@$x,$y';
	}

	public function getCx(ld:LayerDef) {
		return Std.int( ( x + (def.pivotX==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function getCy(ld:LayerDef) {
		return Std.int( ( y + (def.pivotY==1 ? -1 : 0) ) / ld.gridSize );
	}

	public function isOver(levelX:Int, levelY:Int) {
		return levelX >= left && levelX <= right && levelY >= top && levelY <= bottom;
	}

	public function tidy(project:ProjectData) {
		// Remove field instances whose def was removed
		for(e in fieldInstances.keyValueIterator())
			if( e.value.def==null )
				fieldInstances.remove(e.key);
	}

	public function getFieldInstance(fieldDef:FieldDef) {
		if( !fieldInstances.exists(fieldDef.uid) )
			fieldInstances.set(fieldDef.uid, new data.FieldInstance(fieldDef));
		return fieldInstances.get( fieldDef.uid );
	}

}