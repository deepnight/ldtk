package data;

class EntityInstance {
	public var defId(default,null) : Int;
	public var def(get,never) : EntityDef; inline function get_def() return Client.ME.project.getEntityDef(defId);

	public var x : Int;
	public var y : Int;


	public function new(def:EntityDef) {
		defId = def.uid;
	}

	public static function createRender(def:EntityDef, ?parent:h2d.Object) {
		var g = new h2d.Graphics(parent);
		g.beginFill(def.color);
		g.drawRect(0, 0, def.width, def.height);
		return g;
	}
}