package data;

class EntityInstance {
	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return Client.ME.project.getEntityDef(defId); // TODO

	public var x : Int;
	public var y : Int;
	public var fieldInstances : Array<data.FieldInstance> = [];

	public var left(get,never) : Int; inline function get_left() return Std.int( x - def.width*def.pivotX );
	public var right(get,never) : Int; inline function get_right() return left + def.width-1;
	public var top(get,never) : Int; inline function get_top() return Std.int( y - def.height*def.pivotY );
	public var bottom(get,never) : Int; inline function get_bottom() return top + def.height-1;


	public function new(def:EntityDef) {
		defId = def.uid;
		for(fd in def.fieldDefs)
			fieldInstances.push( new data.FieldInstance(fd) );
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

}